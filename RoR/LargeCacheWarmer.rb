##############################
# Large scale of cache warming
##############################
scope :api_eager, lambda { preload(user_alerts: [
                                       :referenced_event,
                                       :referenced_user,
                                       :account_connection,
                                       :user_alert_message_type
                                     ],
                                     account: [
                                       :muted_accounts,
                                       :muted_me,
                                       account_connections: [:connectable],
                                       adults: [
                                         account: [:muted_me]
                                       ],
                                       events: [
                                         :muted_me,
                                         :account,
                                         availability: [
                                            :user,
                                            availability_visibilities: [:account]
                                         ]
                                       ],
                                       connected_accounts: [
                                         adults: [
                                           account: [ 
                                             :muted_me, 
                                             :muted_accounts, 
                                             :muted_events,
                                             muted_relationships: [:muted_object],
                                             muted_me_relationships: [:muted_object],
                                           ]
                                         ],
                                         events: [
                                           :account,
                                           :mutes,
                                           :muted_me,
                                           account_membership: [:account],
                                           availability: [
                                             :user,
                                             available_object: [
                                               account: [
                                                 :muted_accounts,
                                                 muted_relationships: [:muted_object],
                                               ]
                                             ],
                                             availability_visibilities: [:account]
                                           ]
                                         ]
                                       ]
                                     ]
                                    )
                           }