#############################
# Russian doll caching module
#############################
require 'digest/sha1'
require 'securerandom'

module ActiveRussian

  def serializable_object
    if object.class.ancestors.include?(ActiveRecord::Base)
      Rails.cache.fetch cache_key do
        super
      end
    else
      super
    end
  end

  def cache_key
    return [ self.class.name, '/nil' ].join unless object.present?

    cache_key_values = [object.cache_key]

    associations = self.class._associations
    included_associations = filter(associations.keys)

    associations.each do |name, association|
      if included_associations.include? name
        [*self.send(name)].map do |related_object|
          cache_key_values << cache_key_for(association, related_object)
        end
      end
    end

    [self.class.name, '/',  Digest::SHA1.hexdigest(cache_key_values.compact.join)].join
  end

  private

  def cache_key_for(association, related_object)
    case association
    when ActiveModel::Serializer::Association::HasMany
      return serializer_cache_key_for(association.options[:each_serializer].new(related_object, scope: scope)) if association.options[:each_serializer]
    when ActiveModel::Serializer::Association::HasOne
      return serializer_cache_key_for(association.build_serializer(related_object, {scope: scope}.merge(association.options)))
    end

    SecureRandom.hex
  end

  def serializer_cache_key_for(serializer)
    if serializer && serializer.respond_to?(:cache_key)
      serializer.cache_key
    else
      SecureRandom.hex
    end
  end
end


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


#####################################################################################################################
# As the Event owner, that should not allow me to see everyone's schedules to my event regardless
# of their schedule visibility
# (user A creates event, should not be able ot see User B's 'only me' level schedule just because user A was creator)
#####################################################################################################################
def self.visible_to(user)
  # get the ids of all schedules for which user has a specific visibility
  visible_schedule_ids = ScheduleVisibility.owned_by(user.family.adults + [user.family]).pluck(:schedule_id)
  # get the ids of all cards to which any of user's friends or their family have committed
  friend_schedule_ids = Schedule.not_overridden.where(user_id: user.inclusive_friend_ids).pluck(:id)
  
  joins(:event)
  .where("(`schedules`.`user_id` in (:owner_family_member_ids)) 
          OR 
          (
            `schedules`.`event_permission_id` = :my_group AND 
            `schedules`.`user_id` IN (:user_friend_ids) AND 
            `event`.`draft` = 0 AND 
            `event`.`is_uvite` = 0
          )
          OR 
          (
            `schedules`.`event_permission_id` = :certain_families AND 
            `schedules`.`id` IN (:visible_schedule_ids) AND 
            `event`.`draft` = 0
          )
          OR 
          (
            (
              `schedules`.`event_permission_id` = :my_group OR 
              `schedules`.`event_permission_id` = :certain_families
            ) 
            AND 
            `schedules`.`id` IN (:friend_schedule_ids) AND 
            `event`.`is_uvite` = 0  AND 
            (
              `event`.`draft` = 0 OR 
              (
                `event`.`owner_type` = 'Family' AND 
                `event`.`owner_id` = :owner_family_id AND 
                `schedules`.event_permission_id != :only_me
              )
            )
          )
          OR 
          (
            `schedules`.`event_permission_id` = :certain_families AND 
            `event`.`owner_type` = 'Family' AND 
            `event`.`owner_id` = :owner_family_id AND 
            `event`.`is_uvite` = 1 AND 
            `event`.`draft` = 0 AND 
            `schedules`.`id` IN (:friend_schedule_ids)
          )",
          {
            owner_id: user.id,
            owner_family_member_ids: user.family.adults.map(&:id),
            my_group: EventPermission.find_id_by_name(:my_group),
            certain_families: EventPermission.find_id_by_name(:certain_families),
            only_me: EventPermission.find_id_by_name(:me),
            user_friend_ids: user.friend_ids,
            visible_schedule_ids: visible_schedule_ids,
            friend_schedule_ids: friend_schedule_ids,
            owner_family_id: user.family.id
          }
  )
  .group("`schedules`.id")
end


######################################################################################
# Particularly useful and rare Arel knowledge. Exceptionaly useful for rescue projects
######################################################################################
def unblocked_subsets
  availabilities = Availability.arel_table
  subsets = Subset.arel_table
  account = Membership.arel_table.alias(:account)
  friends = Connection.arel_table.alias(:friends)
  user = Membership.arel_table.alias(:user)
  devices = Device.arel_table
  mutes = Mute.arel_table.alias(:mutes)
  blocked = Mute.arel_table.alias(:blocked)
  sqlblock = 
  availabilities.  
    join(subsets).on(availabilities[:available_object_id].eq(subsets[:id])).
    join(account).on(subsets[:id].eq(account[:member_id])).
    join(friends).on(account[:account_id].eq(friends[:account_id])).
    join(user).on(user[:account_id].eq(friends[:connectable_id])).
    join(mutes, Arel::Nodes::OuterJoin).on(mutes[:account_id].eq(user[:account_id]).and(mutes[:muted_object_id].eq(subsets[:id]))).
    join(blocked, Arel::Nodes::OuterJoin).on(blocked[:account_id].eq(account[:account_id]).and(blocked[:muted_object_id].eq(user[:account_id]))).
    where(user[:member_type].eq('user').
          and(account[:member_type].eq('subset')).
          and(mutes[:id].eq(nil).or(mutes[:muted_object_type].not_eq('subset'))).
          and(blocked[:id].eq(nil).or(blocked[:muted_object_type].not_eq('account'))).
          and(user[:account_id].eq(self.account.id))
          ).
    project(subsets[:id]).to_sql
  self.connected_subsets.where( id: sqlblock )
end
