#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'support/pages/page'

module Pages
  class TeamPlanner < ::Pages::Page
    include ::Components::NgSelectAutocompleteHelpers

    attr_reader :project,
                :filters

    def initialize(project)
      super()

      @project = project
      @filters = ::Components::WorkPackages::Filters.new
    end

    def path
      project_team_planner_path(project)
    end

    def expect_title(title = 'Unnamed team planner')
      expect(page).to have_selector '.editable-toolbar-title--fixed', text: title
    end

    def expect_assignee(user, present: true)
      name = user.is_a?(User) ? user.name : user.to_s
      expect(page).to have_conditional_selector(present, '.fc-resource', text: name, wait: 10)
    end

    def add_item(assignee, start_date, end_date)
      script = <<~JS
        var event = new CustomEvent(
          'teamPlannerSelectDate',
          {
            detail: {
              assignee: arguments[0],
              start: arguments[1],
              end: arguments[2]
            }
          });

        document.dispatchEvent(event);
      JS

      page.execute_script(script, assignee, start_date, end_date)
      ::Pages::SplitWorkPackageCreate.new project: project
    end

    def remove_assignee(user)
      page.find(%([data-qa-remove-assignee="#{user.id}"])).click
    end

    def within_lane(user, &block)
      raise ArgumentError.new("Expected instance of principal") unless user.is_a?(Principal)

      type = ::API::V3::Principals::PrincipalType.for(user)
      href = ::API::V3::Utilities::PathHelper::ApiV3Path.send(type, user.id)

      page.within(%(.fc-timeline-lane[data-resource-id="#{href}"]), &block)
    end

    def expect_event(work_package, present: true)
      expect(page).to have_conditional_selector(present, '.fc-event', text: work_package.subject)
    end

    def open_split_view(work_package)
      page
        .find('.fc-event', text: work_package.subject)
        .click

      ::Pages::SplitWorkPackage.new(work_package, project)
    end

    def click_add_user
      page.find('[data-qa-selector="tp-assignee-add-button"]').click
    end

    def select_user_to_add(name)
      select_autocomplete page.find('[data-qa-selector="tp-add-assignee"]'),
                          query: name,
                          results_selector: 'body'
    end

    def search_user_to_add(name)
      search_autocomplete page.find('[data-qa-selector="tp-add-assignee"]'),
                          query: name,
                          results_selector: 'body'
    end
  end
end
