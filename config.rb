
# this class is used to handle a config file written in #YAML.
class ConfigFileHandler

  # create a new #ConfigFileHandler object to handle the give +file+.
  def initialize(file)
    @file = file
  end

  # load configuration stored in +file+.
  def load!
    @config = YAML.load_file @file
  end

  # get a option that should be stored in the +file+.
  def get key
    @config[key.to_s]
  end

  # set a option that should be stored in the +file+.
  def set key, value
    @config[key.to_s] = value
  end

  # save current state.
  def save!
    File.open(@file, 'w') { |f| f.puts @config.to_yaml }
  end
end

