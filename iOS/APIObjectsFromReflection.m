//
// Populating objects from API using reflection
//
- (void)updateWithAPIData:(NSDictionary *)userData inContext:(NSManagedObjectContext *)context
{
    id localSelf = self;//[self MR_inContext:context];
  
    NSArray *keys = [userData allKeys];
    
    // Checks each object property for corresponding API data
    [self reflectOverPropertyDataWithBlock:^(NSDictionary *propertyData) {
        NSString *underscoreKey = [propertyData[@"name"] underscore];
        NSString *key = propertyData[@"name"];
        
        if ([keys containsObject:underscoreKey] &&
            ![userData[underscoreKey] isKindOfClass:[NSNull class]] &&
            ![propertyData[@"readOnly"] boolValue])
        {
            if ([propertyData[@"type"] isEqualToString:@"NSString"])
            {
                [localSelf setValue:userData[underscoreKey] forKey:propertyData[@"name"]];
            }
            else if ([propertyData[@"type"] isEqualToString:@"NSDate"])
            {
                [localSelf setValue:[UWAPIClient dateFromAPIDateString:userData[underscoreKey]]
                        forKey:propertyData[@"name"]];
            }
            else if ([propertyData[@"type"] isEqualToString:@"NSNumber"])
            {
                [localSelf setValue:userData[underscoreKey] forKey:propertyData[@"name"]];
            }
            else if ([propertyData[@"type"] isEqualToString:@"NSSet"])
            {
                [localSelf updateRelationshipWithName:propertyData[@"name"] key:key data:userData[underscoreKey] inContext:context];
            }
            else if ([NSClassFromString(propertyData[@"type"]) isSubclassOfClass:[NSManagedObject class]])
            {
              Class klass = NSClassFromString(propertyData[@"type"]);
              id relatedObject = [klass createOrUpdateFirstFromAPIData:userData[underscoreKey] inContext:context];
              [localSelf setValue:relatedObject forKey:key];
            }
            else
            {
                NSLog(@"UNHANDLED DATA TYPE");
            }
        }
        else if([keys containsObject:underscoreKey] && [userData[underscoreKey] isKindOfClass:[NSNull class]])
        {
            
            [localSelf setValue:nil forKey:key];
        }
        else if([key isEqualToString:@"lastName"]){
            NSArray* sepName = [userData[@"full_name"] componentsSeparatedByString:@" "];
            if([sepName count] > 1)
                [localSelf setValue:sepName[1] forKey:propertyData[@"name"]];
        }
    }];
}

- (void) updateRelationshipWithName:(NSString *)name key:(NSString *)key data:(id)data inContext:(NSManagedObjectContext *)context
{
    id localSelf =  self;
    NSRelationshipDescription* rel = [[[localSelf entity] relationshipsByName] valueForKey:key];
    NSString* className = [[rel destinationEntity] managedObjectClassName];
    
    Class klass = NSClassFromString(className);
    
    // Only continue if we're dealing with remote object descendants
    if (![klass isSubclassOfClass:[RemoteObject class]]) return;
    
    if (className && [data isKindOfClass:[NSArray class]])
    {
        NSString *addObjectsMethodName = [[NSString stringWithFormat:@"add_%@:", [key underscore]] camelizeWithLowerFirstLetter];
        SEL addObjectsSelector = NSSelectorFromString(addObjectsMethodName);

        NSString *removeObjectsMethodName = [[NSString stringWithFormat:@"remove_%@:", [key underscore]] camelizeWithLowerFirstLetter];
        SEL removeObjectsSelector = NSSelectorFromString(removeObjectsMethodName);
      
        // Only continue if the appropriate set selector exists
        if (![self respondsToSelector:addObjectsSelector]) return;
        if (![self respondsToSelector:removeObjectsSelector]) return;
      
        NSMutableSet *newObjects = [[NSMutableSet alloc] init];
        NSMutableSet *oldObjects = [[localSelf valueForKey:key] mutableCopy];

        for (NSDictionary *nestedObjectData in data)
        {
            NSManagedObject *newObject = [klass createOrUpdateFirstFromAPIData:nestedObjectData inContext:context];
            [newObjects addObject:newObject];
        }

       NSMutableSet *toAdd = [newObjects mutableCopy];
       [toAdd minusSet:oldObjects];
      
       [oldObjects minusSet:newObjects];
      
        //Remove old objects
       ((void (*)(id, SEL, id))[self methodForSelector:removeObjectsSelector])(self, removeObjectsSelector, oldObjects);
      
       // Add new objects
       ((void (*)(id, SEL, NSSet *))[self methodForSelector:addObjectsSelector])(self, addObjectsSelector, toAdd);
    }
    else
    {
        NSLog(@"Error loading data for key %@", key);
    }
}