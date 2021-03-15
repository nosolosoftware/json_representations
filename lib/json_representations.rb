require 'json_representations/collection.rb'

module JsonRepresentations
  QUERY_METHODS = %i[includes eager_load preload].freeze

  module ClassMethods
    def representation(name, options={}, &block)
      @representations ||= {}
      @representations[name] = options.merge(name: name, class: self, block: block)

      # copy parent representation options that should be inherited
      return unless options[:extend]
      extend_representation_name = options[:extend] == true ? name : options[:extend]
      extend_representation = (parent_entity || self).representations[extend_representation_name]

      QUERY_METHODS.each do |option|
        next unless (extend_option_value = extend_representation[option])
        @representations[name][option] = extend_option_value + (options[option] || [])
      end
    end

    def representations
      @representations
    end

    def parent_entity
      @parent_entity
    end

    def find_representation(name)
      representations[name] || @parent_entity&.find_representation(name) if name
    end

    def render_representation(object, representation_name, options)
      return {} unless (representation = find_representation(representation_name))

      data = {}
      loop do
        data = object.instance_exec(
          options,
          &representation[:block]
        ).merge(data)

        representation =
          if representation[:extend] == true
            representation[:class].parent_entity&.find_representation(representation[:name])
          else
            find_representation(representation[:extend])
          end

        return data unless representation
      end
    end
  end

  def self.included(base)
    base.extend ClassMethods

    base.class_eval do
      eval %{
        def representation(name, options={})
          #{base}.render_representation(self, name.to_sym, options.dup)
        end
      }

      def self.included(base)
        if base.class == Module
          JsonRepresentations.send(:included, base)
          base.instance_variable_set :@parent_entity, self
        else
          context = self
          base.define_singleton_method(:representations) { context.representations }
        end
      end
    end
  end
end

Array.include(JsonRepresentations::Collection)

if defined?(Mongoid::Criteria)
  Mongoid::Criteria.include(JsonRepresentations::Collection)
end

if defined?(ActiveRecord::Relation)
  ActiveRecord::Relation.include(JsonRepresentations::Collection)
end
