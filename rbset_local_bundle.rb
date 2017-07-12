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
    # TODO: cp -s ain't on OS X. ln won't recurse, so ... just need to recurse ourselves, creating dirs, and links.
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
      extensions_entry,
      [File.join(@root, 'gems', "#{gem_filename}", '*'), File.join('gems', "#{gem_filename}")],
      [File.join(@root, 'specifications', "#{gem_filename}.gemspec"), File.join('specifications')]
    ].compact
  end

  def extensions_entry
    hit = Dir[File.join(@root, 'extensions', '**', "#{gem_version}")].first.to_s
    unless hit.empty?
      [File.join(hit, '*'), hit.sub("#{@root}/", '')]
    end
  end

  def gem_version
    "#{@name}-#{@version.to_s}"
  end

  def gem_filename
    @gem_filename ||= begin
      # dunno if can do optional characters in glob. so ... two globs
      glob_generic = File.join(@root, 'cache', "#{gem_version}.gem")

      # looking for native gems with platform in the name
      glob_platform = File.join(@root, 'cache', "#{gem_version}-*.gem")
      File.basename((Dir[glob_generic] + Dir[glob_platform]).first.to_s.sub(/\.gem\z/, ''))
    end
  end
end

system 'bundle config --local path .bundle'
system 'bundle config --local disable_shared_gems true'

lockfile = File.join(Dir.pwd, 'Gemfile.lock')
puts "Parsing #{lockfile}..."
parser = Bundler::LockfileParser.new(Bundler.read_file(lockfile))

# pp parser.specs.detect { |s| s.name =~ /lib/ }; exit

@root = File.expand_path("~/.bundle/ruby/#{ruby_version}")
@dst = File.join(Dir.pwd, '.bundle', 'ruby', ruby_version)

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
