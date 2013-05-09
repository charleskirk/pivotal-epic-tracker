require "pivotal-tracker"
require "pivotal-epic-tracker/version"

# Public: A gem that utilizes the pivotal-tracker gem to track epic's
# the way we do at chimp (http://chimp.net).
#
# Return epic status information for a project and label. An epic
# is in one of the following states:
#   Specced: if there is a needs-design label on associated ticket
#   Designed: if there is a ready-to-code label on associated ticket
#   Tested: if all tickets are accepted
#
module PivotalEpicTracker

  def connect_to_project(token, project_id, use_ssl = true)
    PivotalTracker::Client.token = token
    PivotalTracker::Client.use_ssl = use_ssl
    PivotalTracker::Project.find(project_id)
  end

  # Public: return an EpicStatus object giving visibility to a Pivotal Epic
  # and whether it is specced, designed, tested. Also gives visibility to the 
  # number of total stories and how many of those are delivered.
  #
  def get_epic_statuses(project)
    e = EpicStatus.new(project)
    e.get_statuses
    e
  end

  class EpicStatus
    attr_accessor :num_stories, :num_stories_delivered, :epic_statuses

    def initialize(project)
      @project = project
      @stories_labels = @project.labels.split(',')
    end

    def get_statuses
      self.epic_statuses = get_next_release_labels
    end
    
    def get_status(label)
      self.num_stories = @stories.size
      self.num_stories_delivered = get_num_stories_delivered
    end
    
    def get_percentage_complete(label)
      stories_delivered = 0
      allStories = get_stories(label)
      allStories.each {|s| stories_delivered += 1 if s.current_state == 'delivered' || s.current_state == 'accepted'}
      return false if allStories.size == 0
      if !stories_delivered
        percent = 0
      else
        percent = (stories_delivered.to_f/allStories.size.to_f)*100
      end
      percent
    end
    
    def get_next_release_labels
      @labels = []
      @releases = []
      @stories_labels.each do |label|
        if label[0..2] == 'ver' && label[3] != 's' && label[3] != ' '
          @labels << label
        end
      end
      @labels.sort!
      @labels.each do |label|
        percent = get_percentage_complete(label)
        next if percent == 100 || percent == false
        @releases << {
          :release => label.split('ver')[1],
          :percentage_complete => percent
        }
      end
      @releases
    end

    def get_stories(label)
      @project.stories.all(:label => label, :includedone => true)
    end

    def get_num_stories_delivered
      stories_delivered = 0
      @stories.each {|s| stories_delivered += 1 if s.current_state == 'delivered' || s.current_state == 'accepted'}
      stories_delivered
    end

  end
end
