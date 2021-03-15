module JsonRepresentations
  module Collection
    def self.included(base)
      base.class_eval do
        def representation(name=nil, options={})
          subject = self

          if respond_to?(:klass) && klass.respond_to?(:representations)
            # call supported methods of ActiveRecord::QueryMethods
            QUERY_METHODS.each do |method|
              next unless respond_to? method

              args = klass.representations.dig(name, method)

              # we need to reassign because ActiveRecord returns new object
              subject = subject.public_send(method, args) if args
            end
          end

          return super if respond_to? :super

          subject.map do |item|
            item.respond_to?(:representation) ? item.representation(name, options) : item
          end
        end
      end
    end
  end
end
