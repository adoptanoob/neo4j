SerializedProperties
====================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   SerializedProperties/ClassMethods




Constants
---------





Files
-----



  * `lib/neo4j/shared/serialized_properties.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/serialized_properties.rb#L7>`_





Methods
-------



.. _`Neo4j/Shared/SerializedProperties#serializable_hash`:

**#serializable_hash**
  

  .. hidden-code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end



.. _`Neo4j/Shared/SerializedProperties#serialized_properties`:

**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
     end





