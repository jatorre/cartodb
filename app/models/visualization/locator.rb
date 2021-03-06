# encoding: utf-8
require_relative '../visualization'
require_relative './member'
require_relative '../user'
require_relative '../table'

module CartoDB
  module Visualization
    class Locator
      def initialize(user_model=nil)
        @user_model   = user_model  || ::User
      end #initialize

      def get(id_or_name, subdomain, filters={})
        user = user_from(subdomain)

        visualization_from(id_or_name, user, filters) ||
        table_from(id_or_name, user)         ||
        [nil, nil]
      end

      private

      attr_reader :user_model

      def user_from(subdomain)
        @user ||= user_model.where(username: subdomain).first
      end

      def visualization_from(id_or_name, user, filters)
        visualization = nil

        visualization = get_by_name(id_or_name, user, filters) if user
        visualization = get_by_id(id_or_name, filters) if visualization.nil?

        return false if visualization.nil?

        [visualization, visualization.table]
      end

      # TODO: Check if we still need this, as everything comes loaded from Vis collections now
      def table_from(id_or_name, user)
        table = ::Table.get_by_id(id_or_name, user)
        return false unless table && table.table_visualization
        [table.table_visualization, table]
      rescue
        false
      end
        
      def get_by_id(uuid, filters)
        params = {
          id: uuid
        }
        Visualization::Collection.new.fetch(params.merge(filters)).first
      rescue KeyError
        nil
      end

      def get_by_name(name, user, filters)
        params = {
          name:   name,
          user_id: user.id
        }
        Visualization::Collection.new.fetch(params.merge(filters)).first
      rescue KeyError
        nil
      end
    end
  end
end

