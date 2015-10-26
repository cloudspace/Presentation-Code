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