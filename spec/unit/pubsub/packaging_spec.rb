# encoding: utf-8
require 'spec_helper'

# The Ably namespace is assembled at install time from two gems: ably-pubsub-core ships the
# implementation under lib/ably — including lib/ably/pubsub/http and lib/ably/pubsub/realtime —
# and ably-pubsub-server ships only the lib/ably/pubsub/server subtree on top of it. Both gems
# therefore write into lib/ably/pubsub, which makes the no-overlap rule below load-bearing
# rather than incidental. That only holds together if each gem ships exactly its own subtree —
# a file shipped by both would be resolved from whichever gem comes first on the load path,
# hiding the other's copy. The release pre-flight checks version agreement but nothing else
# asserts the gems' file lists, so a packaging mistake would otherwise surface only after
# publish. These specs load the gemspecs and check the built file lists directly.
describe 'Pub/Sub gem packaging' do
  repo_root = File.expand_path('../../..', __dir__)

  gemspec_for = lambda do |gem_name, dir|
    path = File.join(repo_root, dir, "#{gem_name}.gemspec")
    Gem::Specification.load(path) || raise("could not load #{path}")
  end

  core_spec = gemspec_for.call('ably-pubsub-core', 'core')
  server_spec = gemspec_for.call('ably-pubsub-server', 'server')

  it 'ships no load-path file in both gems' do
    core_lib = core_spec.files.grep(%r{\Alib/})
    server_lib = server_spec.files.grep(%r{\Alib/})
    expect(core_lib & server_lib).to be_empty
  end

  it 'core does not ship the server subtree' do
    expect(core_spec.files.grep(%r{\Alib/ably/pubsub/server(/|\.rb\z)})).to be_empty
  end

  # Core owns everything under lib/ably/pubsub except the server subtree, so it must
  # not claim the bare namespace paths the server gem would otherwise be free to add.
  it 'core ships its own pubsub subtrees' do
    expect(core_spec.files).to include('lib/ably/pubsub.rb')
    expect(core_spec.files.grep(%r{\Alib/ably/pubsub/http/})).to_not be_empty
    expect(core_spec.files.grep(%r{\Alib/ably/pubsub/realtime/})).to_not be_empty
  end

  it 'server ships only the lib/ably/pubsub/server subtree under lib' do
    lib_files = server_spec.files.grep(%r{\Alib/})
    expect(lib_files).to_not be_empty
    expect(lib_files).to all(match(%r{\Alib/ably/pubsub/server(/|\.rb\z)}))
  end

  it 'core does not ship the ably-common submodule' do
    expect(core_spec.files.grep(%r{\Alib/submodules/})).to be_empty
  end

  # spec.files comes from `git ls-files`, so a Ruby file that has not been added to the
  # index is silently left out of the built gem, and the omission surfaces only as a
  # LoadError or NameError on a consumer's machine after publish.
  source_files_on_disk = lambda do |dir|
    Dir.glob(File.join(repo_root, dir, 'lib/**/*.rb'))
       .map { |path| path.sub(File.join(repo_root, dir, ''), '') }
       .reject { |path| path.start_with?('lib/submodules/') }
  end

  it 'core ships every Ruby file under core/lib' do
    on_disk = source_files_on_disk.call('core')
    expect(on_disk).to_not be_empty
    expect(on_disk - core_spec.files).to be_empty
  end

  it 'server ships every Ruby file under server/lib' do
    on_disk = source_files_on_disk.call('server')
    expect(on_disk).to_not be_empty
    expect(on_disk - server_spec.files).to be_empty
  end

  it 'releases both gems at one version (lockstep)' do
    expect(server_spec.version).to eql(core_spec.version)
  end

  it 'server pins core at exactly the shared version' do
    core_dep = server_spec.dependencies.find { |dep| dep.name == 'ably-pubsub-core' }
    expect(core_dep).to_not be_nil
    expect(core_dep.requirement.to_s).to eql("= #{core_spec.version}")
  end
end
