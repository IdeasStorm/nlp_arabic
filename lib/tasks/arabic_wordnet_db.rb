# Download Arabic Wordnet DB and extract it to db folder

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

task :download_db do
  download ZIP_ArWN_URL, ZIP_LOC
end