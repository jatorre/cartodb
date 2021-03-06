# encoding: utf-8
require_relative '../../../lib/varnish/lib/cartodb-varnish'
require_relative '../user'

module CartoDB
  class TablePrivacyManager
    def initialize(table)
      @table  = table
    end

    def set_public
      self.privacy = ::Table::PRIVACY_PUBLIC
      set_database_permissions(grant_query)
      self
    end

    def set_private
      self.privacy = ::Table::PRIVACY_PRIVATE
      set_database_permissions(revoke_query)
      self
    end

    def set_from_table_privacy(table_privacy)
      case table_privacy
        when ::Table::PRIVACY_PUBLIC
          set_public
        when ::Table::PRIVACY_LINK
          set_public_with_link_only
        else
          set_private
      end
    end

    def set_from(visualization)
      set_public                if visualization.public?
      set_public_with_link_only if visualization.public_with_link?
      set_private               if visualization.private? or visualization.organization?
      table.update(privacy: privacy)
      self
    end

    def propagate_to(visualization)
      visualization.store_using_table({
                                        privacy_text: ::Table::PRIVACY_VALUES_TO_TEXTS[privacy],
                                        map_id: visualization.map_id
                                      })
      self
    end

    def privacy_for_redis
      case @table.privacy
        when ::Table::PRIVACY_PUBLIC, ::Table::PRIVACY_LINK
          ::Table::PRIVACY_PUBLIC
        else
          ::Table::PRIVACY_PRIVATE
      end
    end

    def propagate_to_redis_and_varnish
      raise 'table privacy cannot be nil' unless privacy
      # TODO: Improve this, hack because tiler checks it
      $tables_metadata.hset redis_key, 'privacy', privacy_for_redis
      invalidate_varnish_cache
      self
    end

    private

    attr_reader   :table
    attr_accessor :privacy

    def set_public_with_link_only
      self.privacy = ::Table::PRIVACY_LINK
      set_database_permissions(grant_query)
    end

    def owner
      @owner ||= User.where(id: table.user_id).first
    end

    def set_database_permissions(query)
      owner.in_database(as: :superuser).run(query)
    end

    def revoke_query
      %Q{
        REVOKE SELECT ON "#{owner.database_schema}"."#{table.name}"
        FROM #{CartoDB::PUBLIC_DB_USER}
      }
    end

    def grant_query
      %Q{
        GRANT SELECT ON "#{owner.database_schema}"."#{table.name}"
        TO #{CartoDB::PUBLIC_DB_USER};
      }
    end

    def invalidate_varnish_cache
      Varnish.new.purge("#{varnish_key}")
    end

    def varnish_key
      if table.owner.cartodb_extension_version_pre_mu?
        "^#{table.owner.database_name}:(.*#{table.name}.*)|(table)$"
      else
        "^#{table.owner.database_name}:(.*#{owner.database_schema}\\.#{table.name}.*)|(table)$"
      end
    end

    def redis_key
      "rails:#{table.owner.database_name}:#{owner.database_schema}.#{table.name}"
    end
  end
end

