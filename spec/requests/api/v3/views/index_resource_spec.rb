#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'spec_helper'
require 'rack/test'

describe ::API::V3::Views::ViewsAPI,
         'index',
         type: :request,
         content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:permitted_user) { FactoryBot.create(:user) }
  shared_let(:role) do
    FactoryBot.create(:role, permissions: [:view_work_packages])
  end
  shared_let(:project) do
    FactoryBot.create(:project,
                      members: { permitted_user => role })
  end
  shared_let(:user_private_project_query) do
    FactoryBot.create(:query,
                      user: permitted_user,
                      project: project,
                      is_public: false)
  end
  shared_let(:user_private_project_view) do
    FactoryBot.create(:view_work_packages_table,
                      query: user_private_project_query)
  end
  shared_let(:other_user_private_project_query) do
    FactoryBot.create(:query,
                      project: project,
                      is_public: false)
  end
  shared_let(:other_user_private_project_view) do
    FactoryBot.create(:view_work_packages_table,
                      query: other_user_private_project_query)
  end
  shared_let(:user_public_project_query) do
    FactoryBot.create(:query,
                      project: project,
                      is_public: true)
  end
  shared_let(:user_public_project_view) do
    FactoryBot.create(:view_work_packages_table,
                      query: user_public_project_query)
  end
  shared_let(:other_project) do
    FactoryBot.create(:project,
                      members: { permitted_user => role })
  end
  shared_let(:user_private_other_project_query) do
    FactoryBot.create(:query,
                      user: permitted_user,
                      project: other_project)
  end
  shared_let(:user_private_other_project_view) do
    FactoryBot.create(:view_work_packages_table,
                      query: user_private_other_project_query)
  end

  let(:views) do
    [user_private_project_view,
     user_private_other_project_view,
     user_public_project_view,
     other_user_private_project_view]
  end

  let(:filters) { nil }

  let(:send_request) do
    get api_v3_paths.path_for :views, filters: filters
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  current_user { permitted_user }

  before do
    views

    send_request
  end

  context 'without any filter' do
    it_behaves_like 'API V3 collection response', 3, 3, 'Views::WorkPackagesTable' do
      let(:elements) do
        [
          user_private_other_project_view,
          user_public_project_view,
          user_private_project_view
        ]
      end
    end
  end

  context 'with a project filter' do
    let(:filters) do
      [
        {
          'project' => {
            'operator' => '=',
            'values' => [project.id.to_s]
          }
        }
      ]
    end

    it_behaves_like 'API V3 collection response', 2, 2, 'Views::WorkPackagesTable' do
      let(:elements) do
        [
          user_public_project_view,
          user_private_project_view
        ]
      end
    end
  end

  context 'with a type filter' do
    let(:other_user_private_project_query) do
      FactoryBot.create(:query,
                        user: permitted_user,
                        project: project,
                        is_public: false)
    end

    let(:user_private_project_team_planner_view) do
      FactoryBot.create(:view_team_planner,
                        query: other_user_private_project_query)
    end

    let(:views) do
      [
        user_private_project_team_planner_view,
        user_public_project_view
      ]
    end

    let(:filters) do
      [
        {
          'type' => {
            'operator' => '=',
            'values' => ['Views::TeamPlanner']
          }
        }
      ]
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'Views::TeamPlanner' do
      let(:elements) do
        [
          user_private_project_team_planner_view
        ]
      end
    end
  end

  context 'for a user without any visible queries' do
    current_user { FactoryBot.create(:user) }

    it_behaves_like 'API V3 collection response', 0, 0, 'Views::WorkPackagesTable'
  end
end
