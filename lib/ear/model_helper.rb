module ModelHelper

  def self.included(base)
    base.class_eval do
      #
      # gangster method_missing magic to automatically create tasks by name
      #

      #def respond_to?(method,include_private = false)
      #  TaskManager.instance.get_tasks_for(self).each do |task|
      #    return true if method =~ Regexp.new(task.name)
      #  end
      #  return false
      #end

      def method_missing(method, *args, &block)
         call_parent = true
         TaskManager.instance.get_tasks_for(self).each do |task|
          puts "checking task #{task}"
          if method =~ Regexp.new(task.name)
            #
            # Run the task, and mark calling super as unnecessary.
            #
            task_arguments = args.first || {}
            self.run_task task.name, task_arguments
            call_parent = false

            # Define this method, so we don't have to check again
            # this is like caching the method missing. Should take 
            # care of a respond_to? call as well. See:
            # http://www.alfajango.com/blog/method_missing-a-rubyists-beautiful-mistress/
            self.class.send(:define_method, task.name, *args) do
              self.run_task task.name, args.first || {}
              call_parent = false
            end
          end
        end
        super if call_parent
      end
      # end method_missing magic

      def to_s
        "#{self.class} #{self.name}"
      end
      
      def underscore
        ActiveSupport::Inflector.underscore self.class
      end
      
      
      #
      # This method lets you query the available tasks for this object type
      #
      def tasks
        EarLogger.instance.log "Getting tasks for #{self}"
        TaskManager.instance.get_tasks_for(self)
      end

      #
      # This method lets you run a task on this object
      #
      def run_task(task_name, options={})
        EarLogger.instance.log "Asking task manager to queue task #{task_name} run on #{self} with options: #{options}"
        TaskManager.instance.queue_task_run(task_name, self, options)
      end

      #
      # This method lets you find all available children
      #
      def children
        EarLogger.instance.log "Finding children for #{self}"
        ObjectManager.instance.find_children(self.id, self.class.to_s)
      end

      #
      # This method lets you find all available parents
      #
      def parents
        EarLogger.instance.log "Finding parents for #{self}"
        ObjectManager.instance.find_parents(self.id, self.class.to_s)
      end

      #
      # This method lets you find all available parents
      #
      def parent_tasks
        EarLogger.instance.log "Finding task runs for #{self}"
        ObjectManager.instance.find_task_runs(self.id, self.class.to_s)
      end
      
      #
      # This method associates a child with this object
      #
      def associate_child(params)
        # Pull out the relevant parameters
        new_object = params[:child]
        task_run = params[:task_run]

        # grab the object's class
        class_name = new_object.class.to_s.downcase
        
        # see if we have a collection of these things and add it if 
        #  we do.       
=begin        
        begin 
          if eval("self.#{class_name}s")
            EarLogger.instance.log_good "Adding #{new_object} to #{self}"
            # If so, then add it to the collection
            eval "self.#{class_name}s << object"
          # if not, try to associate a singular object
          elsif eval("self.#{class_name}")
            EarLogger.instance.log_good "Setting #{new_object}.#{class_name} to #{self}"
            # Set it 
            eval "self.#{class_name}.id=object.id"
          else
            EarLogger.instance.log_good "Simply associating, not adding to the collection"      
          end
        rescue
          EarLogger.instance.log_debug "self.#{class_name} doesn't exist, caught."
        end
=end
        # And set us up as a parent through an object_mapping
        # new_object._map_parent(params)  
         # And associate the object as a child through an object_mapping
        EarLogger.instance.log "Associating #{self} with child object #{new_object}"
        _map_child(params)
      end
      
      # 
      # This method returns a pretty print version of the relationships
      #  of this object
      # 
      def to_graph(indent=nil)
        out = "Parents:\n"
        self.parents.each { |parent| out << " #{parent}" }
        out << "\nObject: #{self.to_s}\n"
        out << "Children:\n"
        self.children.each { |child| out << " #{child}" }
        out
      end

=begin
      # Don't call this method directly, use associate
      def _map_parent(params)      
        EarLogger.instance.log "Creating new parent mapping: #{params[:child]} => #{self}"
        ObjectMapping.create(   
          :parent_id => params[:child].id,
          :parent_type => params[:child].class.to_s,
          :child_id => self.id,
          :child_type => self.class.to_s,
          :task_run_id => params[:task_run].id || nil)
      end
=end  
      def _map_child(params)
        #begin
          EarLogger.instance.log "Creating new child mapping #{self} => #{params[:child]}"
          ObjectMapping.create(
            :parent_id => self.id,
            :parent_type => self.class.to_s,
            :child_id => params[:child].id,
            :child_type => params[:child].class.to_s,
            :task_run_id => params[:task_run].id || nil)      
        #rescue
        #  EarLogger.instance.log_error "Could not create mapping from #{self} => #{params[:child]} - are you sure this object exists in the DB?"
        #end
      end
    end
  end
end
