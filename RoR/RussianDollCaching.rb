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