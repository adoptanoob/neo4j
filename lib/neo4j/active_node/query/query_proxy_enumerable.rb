module Neo4j
  module ActiveNode
    module Query
      # Methods related to returning nodes and rels from QueryProxy
      module QueryProxyEnumerable
        include Enumerable

        # Just like every other <tt>each</tt> but it allows for optional params to support the versions that also return relationships.
        # The <tt>node</tt> and <tt>rel</tt> params are typically used by those other methods but there's nothing stopping you from
        # using `your_node.each(true, true)` instead of `your_node.each_with_rel`.
        # @return [Enumerable] An enumerable containing some combination of nodes and rels.
        def each(node = true, rel = nil)
          if node && rel
            enumerable_query(identity, rel_var).each { |returned_node, returned_rel| yield returned_node, returned_rel }
          else
            pluck_this = !rel ? identity : @rel_var
            enumerable_query(pluck_this).each { |returned_node| yield returned_node }
          end
        end

        # When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
        # For example, to return the relationship between a given student and their lessons:
        #   student.lessons.each_rel do |rel|
        # @return [Enumerable] An enumerable containing any number of applicable relationship objects.
        def each_rel(&block)
          block_given? ? each(false, true, &block) : to_enum(:each, false, true)
        end

        # When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
        # For example, to return a lesson and each relationship to a given student:
        #   student.lessons.each_with_rel do |lesson, rel|
        def each_with_rel(&block)
          block_given? ? each(true, true, &block) : to_enum(:each, true, true)
        end

        # Does exactly what you would hope. Without it, comparing `bobby.lessons == sandy.lessons` would evaluate to false because it
        # would be comparing the QueryProxy objects, not the lessons themselves.
        def ==(other)
          self.to_a == other
        end

        # For getting variables which have been defined as part of the association chain
        def pluck(*args)
          self.query.pluck(*args)
        end

        protected

        def preload(rel)
          pluck_this = rel.nil? ? [preloader.target_id, "collect(#{preloader.child_id})"] : [preloader.target_id, preloader.rel_id, "collect(#{preloader.child_id})", "collect(#{rel})"]
          return preload_pluck(pluck_this, rel) if @association.nil? || caller.nil?
          cypher_string = self.to_cypher_with_params(pluck_this)
          caller.association_instance_get(cypher_string, @association) || preload_set_association_instance(pluck_this, rel, cypher_string)
        end

        def preload_pluck(pluck_this, rel)
          self.pluck(*pluck_this).tap do |result|
            if rel
              result.each { |target, _returned_rel, child, child_rel| preloader.replay(target, [child << child_rel.first], true) }
            else
              result.each { |target, child| preloader.replay(target, child) }
              result.map!(&:first)
            end
          end
        end

        private

        # Executes the query against the database if the results are not already present in a node's association cache. This method is
        # shared by <tt>each</tt>, <tt>each_rel</tt>, and <tt>each_with_rel</tt>.
        # @param [String,Symbol] node The string or symbol of the node to return from the database.
        # @param [String,Symbol] rel The string or symbol of a relationship to return from the database.
        def enumerable_query(node, rel = nil)
          if preloader
            preload(rel)
          else
            pluck_this = rel.nil? ? [node] : [node, rel]
            return self.pluck(*pluck_this) if @association.nil? || caller.nil?
            cypher_string = self.to_cypher_with_params(pluck_this)
            caller.association_instance_get(cypher_string, @association) || set_association_instance(pluck_this, cypher_string)
          end
        end

        def set_association_instance(pluck_this, cypher_string)
          collection = self.pluck(*pluck_this)
          caller.association_instance_set(cypher_string, collection, @association) unless collection.empty?
          collection
        end

        def preload_set_association_instance(pluck_this, rel, cypher_string)
          collection = self.preload_pluck(pluck_this, rel)
          caller.association_instance_set(cypher_string, collection, preloader.last_association) unless collection.empty?
          collection
        end
      end
    end
  end
end
