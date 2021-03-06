# encoding: utf-8
require_relative '../../lib/importer/runner'
require_relative '../../lib/importer/job'
require_relative '../../lib/importer/downloader'
require_relative '../factories/pg_connection'
require_relative '../doubles/log'
require_relative 'cdb_importer_context'
require_relative 'acceptance_helpers'

include CartoDB::Importer2

describe 'Mapinfo regression tests' do
  include AcceptanceHelpers
  include_context "cdb_importer schema"

  it 'imports Mapinfo files' do
    filepath    = "http://dl.dropboxusercontent.com/u/931536/Ivanovo.zip"
    downloader  = Downloader.new(filepath)
    runner      = Runner.new(@pg_options, downloader, CartoDB::Importer2::Doubles::Log.new)
    runner.run

    geometry_type_for(runner).should be
  end

end # Mapinfo regression tests
 

