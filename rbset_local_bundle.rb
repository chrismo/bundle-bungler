#!/usr/bin/env ruby

require 'bundler'
require 'fileutils'
require 'pp'

def ruby_version
  v = Gem::Version.new(File.read(File.join(Dir.pwd, '.ruby-version')).chomp)
  "#{v.segments[0]}.#{v.segments[1]}.0"
end

class GemSync
  def initialize(dst)
    @dst = dst
  end

  def sync_gems(gem_dirs)
    gem_dirs.each do |gem_dir|
      gem_dir.dirs.each do |src, dst_stub|
        sync_thing(src, dst_stub)
      end
    end
  end

  def sync_thing(src, dst_stub)
    dst = File.join(@dst, dst_stub)
    FileUtils.makedirs dst
    cmd = "rsync -a #{src} #{dst}"
    puts cmd
    system cmd
  end
end

class GitSourceGemDirs
  def initialize(root, name)
    @root = root
    @name = name
  end

  def dirs
    [
      [File.join(@root, 'bundler', 'gems', "#{@name}-*"), File.join('bundler', 'gems')],
      [File.join(@root, 'cache', 'bundler', 'git', "#{@name}-*"), File.join('cache', 'bundler', 'git')]
    ]
  end
end

class GemDirs
  def initialize(root, name, version)
    @root = root
    @name = name
    @version = version
  end

  def dirs
    return [] if gem_filename.empty?
    [
      [File.join(@root, 'cache', "#{gem_filename}.gem"), File.join('cache')],
      [File.join(@root, 'gems', "#{gem_filename}", '*'), File.join('gems', "#{gem_filename}")],
      [File.join(@root, 'specifications', "#{gem_filename}.gemspec"), File.join('specifications')]
    ]
  end

  def gem_filename
    # looking for native gems with platform in the name
    @gem_filename ||= begin
      glob = File.join(@root, 'cache', "#{@name}-#{@version.to_s}*.gem")
      File.basename(Dir[glob].first.to_s.sub(/\.gem\z/, ''))
    end
  end
end

system 'bundle config --local path zz'
system 'bundle config --local disable_shared_gems true'

lockfile = File.join(Dir.pwd, 'Gemfile.lock')
puts "Parsing #{lockfile}..."
parser = Bundler::LockfileParser.new(Bundler.read_file(lockfile))

# pp parser.specs.detect { |s| s.name =~ /lib/ }; exit

@root = "/Users/chrismo/.bundle/ruby/#{ruby_version}"
@dst = File.join(Dir.pwd, 'zz', 'ruby', ruby_version)

FileUtils.makedirs @dst

sync = GemSync.new(@dst)
sync.sync_gems(
  parser.specs.map do |s|
    if s.source.is_a?(Bundler::Source::Git)
      GitSourceGemDirs.new(@root, s.name)
    else
      GemDirs.new(@root, s.name, s.version)
    end
  end
)

# mkdir -p ./zzz/ruby/2.3.0 && rsync -av  ~/.bundle/ruby/2.3.0/ ./zzz/ruby/2.3.0
# if you grab the versions from the Gemfile.lock ... could rsync just the versions?


# [["no_moss", Gem::Version.new("0.5.0")],
#  ["aasm", Gem::Version.new("4.1.0")],
#  ["action_event", Gem::Version.new("2.13.1")],
#  ["actionmailer", Gem::Version.new("4.1.14.2")],
#  ["actionpack", Gem::Version.new("4.1.14.2")],
#  ["actionview", Gem::Version.new("4.1.14.2")],
#  ["activemodel", Gem::Version.new("4.1.14.2")],
#  ["activerecord", Gem::Version.new("4.1.14.2")],