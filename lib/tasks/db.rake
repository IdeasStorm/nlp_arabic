ZIP_ArWN_URL = "http://media.ideasstorm.net/ArabicWordnetDB/ArabicWordnet.zip"
ZIP_LOC = "../../db/ArabicWordnet.zip"

UNZIP_LOC = "../../db"
UNZIP_FILE_NAME = "ArabicWordnet.sqlite"

###############################################
### This code is from wordnet-defaultdb gem ###
###############################################

### Download the file at +sourceuri+ via HTTP and write it to +targetfile+.
def download( sourceuri, targetfile=nil )
  oldsync = $stdout.sync
  $stdout.sync = true
  require 'open-uri'
  require 'pathname'
  targetpath = Pathname.new(targetfile)
  $stderr.puts "Downloading %s to %s" % [sourceuri, targetfile]
  $stderr.puts "  connecting..." if $trace
  ifh = open( sourceuri ) do |ifh|
    $stderr.puts "  connected..." if $trace
    targetpath.open( File::WRONLY|File::TRUNC|File::CREAT, 0644 ) do |ofh|
      $stderr.puts "Downloading..."
      buf = ''
      while ifh.read( 16384, buf )
        until buf.empty?
          bytes = ofh.write( buf )
          buf.slice!( 0, bytes )
        end
      end
      $stderr.puts "Done."
    end
  end
  return targetpath
ensure
  $stdout.sync = oldsync
end

### Extract the contents of the specified +zipfile+ into the given +targetdir+.
def unzip( zipfile, targetdir, *files )
  require 'zip/zip'
  require 'pathname'
  targetdir = Pathname( targetdir )
  raise "No such directory: #{targetdir}" unless targetdir.directory?

  Zip::ZipFile.foreach( zipfile ) do |entry|
    # $stderr.puts "  entry is: %p, looking for: %p" % [ entry.name, files ]
    next unless files.empty? || files.include?( entry.name )
    target_path = targetdir + entry.name
    $stderr.puts "  extracting: %s" % [ target_path ]
    entry.extract( target_path ) { true }
    files.delete( entry.name )
    break if files.empty?
  end

  raise "Couldn't unzip: %p: not found in %s" % [ files, zipfile ] unless files.empty?
end

namespace :db do
  desc "Download Arabic Wordnet DB"
  task :download => :environment do
    download ZIP_ArWN_URL, ZIP_LOC
    unzip ZIP_LOC, UNZIP_LOC, UNZIP_FILE_NAME
  end
end