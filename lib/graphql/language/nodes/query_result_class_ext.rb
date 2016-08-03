require "graphql"
require "graphql/language/nodes/selection_ext"
require "graphql/query_result"

module GraphQL
  module Language
    module Nodes
      module Selections
        # Public: Get GraphQL::QueryResult class for result of query.
        #
        # Returns subclass of QueryResult or nil.
        def query_result_class(**kargs)
          GraphQL::QueryResult.define(fields: selections_query_result_classes(**kargs))
        end

        def selection_query_result_classes(**kargs)
          if kargs[:shadow] && kargs[:shadow].include?(self)
            {}
          else
            selections_query_result_classes(**kargs)
          end
        end

        # Internal: Gather QueryResult classes for each selection.
        #
        # Returns a Hash[String => (QueryResult|nil)].
        def selections_query_result_classes(**kargs)
          self.selections.inject({}) do |h, selection|
            case selection
            when Selection
              h.merge!(selection.selection_query_result_classes(**kargs))
            else
              raise TypeError, "expected selection to be of type Selection, but was #{selection.class}"
            end
          end
        end
      end

      class Field < AbstractNode
        def query_result_class(**kargs)
          if self.selections.any?
            super
          else
            nil
          end
        end

        def selection_query_result_classes(**kargs)
          name = self.alias || self.name
          { name => query_result_class(**kargs) }
        end
      end

      class FragmentSpread < AbstractNode
        def selection_query_result_classes(fragments: {}, **kargs)
          unless fragment = fragments[name.to_sym]
            raise ArgumentError, "missing fragment '#{name}'"
          end
          fragment.selection_query_result_classes(fragments: fragments, **kargs)
        end
      end
    end
  end
end