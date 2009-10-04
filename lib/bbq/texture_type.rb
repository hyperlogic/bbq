require 'fileutils'

# NOTE: requires ImageMagick
class OpenGLTextureType < BaseType

  GL_RGB = 0x1907
  GL_RGBA = 0x1908
  GL_UNSIGNED_BYTE = 0x1401

  class Texture
    attr_reader :width, :height, :internal_format, :format, :type, :pixels

    def initialize hash
      hash.each do |key, value|
        instance_variable_set("@#{key}".to_sym, value)
      end
      raise "Texture has no filename" unless @filename

      # get the image width and height
      str = `identify -format \"%[fx:w] %[fx:h]\" #{@filename}`
      @width, @height = str.split.map {|s| s.to_i}
      puts "#{@filename} is #{@width} x #{@height}"

      # stream the raw image data into a temp file
      `stream -map #{@has_alpha ? "rgba" : "rgb"} -storage-type char #{@filename} pixels.dat`

      # read the file into @pixels
      File.open('pixels.dat', 'rb') do |f|
        @pixels = f.read
      end

      # remove the temp file
      FileUtils.rm 'pixels.dat'

      # set format fields
      format = @has_alpha ? GL_RGBA : GL_RGB
      @internal_format = format
      @format = format
      @type = GL_UNSIGNED_BYTE
    end
  end

  def initialize
    super "OpenGLTexture", 4, nil
  end
  
  def cook chunk, value, name

    # load the texture
    texture = Texture.new value

    # cook the texture data
    $type_registry[:uint32].cook(chunk, texture.width, "#{name}.width")
    $type_registry[:uint32].cook(chunk, texture.height, "#{name}.height")
    $type_registry[:int32].cook(chunk, texture.internal_format, "#{name}.internal_format")
    $type_registry[:int32].cook(chunk, texture.format, "#{name}.format")
    $type_registry[:int32].cook(chunk, texture.type, "#{name}.type")
    image_chunk = Chunk.new
    image_chunk.push(texture.pixels, "#{name} pixels")
    chunk.add_pointer image_chunk
  end

end
$type_registry[:OpenGLTexture] = OpenGLTextureType.new
