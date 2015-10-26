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