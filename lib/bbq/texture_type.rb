require 'fileutils'
require 'zlib'

# NOTE: requires ImageMagick
class OpenGLTextureType < BaseType

  GL_RGB = 0x1907
  GL_RGBA = 0x1908
  GL_UNSIGNED_BYTE = 0x1401

  class Texture
    attr_reader :width, :height, :internal_format, :format, :type, :pixels

    # hash can have the following keys: 
    # :filename => string indicating the path to the texture
    # :has_alpha => true indicates the texture should be RGBA, false is RGB
    # :zlib => true indicates the texture should be deflated using zlib
    #
    def initialize hash
      hash.each do |key, value|
        instance_variable_set("@#{key}".to_sym, value)
      end
      raise "Texture has no filename" unless @filename

      # get the image width and height
      str = `identify -format \"%[fx:w] %[fx:h]\" #{@filename}`
      @width, @height = str.split.map {|s| s.to_i}
      #puts "#{@filename} is #{@width} x #{@height}"

      @pixels = []
      w = @width
      h = @height
      i = 0
      done = false
      while !done

        # flip the scan lines of the image
        temp_image = "temp.#{File.extname(@filename)}"
        `convert -flip -scale #{w}x#{h} #{@filename} #{temp_image}`

        # stream the raw image data into a temp file
        temp_stream = 'pixels.dat'
        `stream -map #{@has_alpha ? "rgba" : "rgb"} -storage-type char #{temp_image} #{temp_stream}`

        # read the file into @pixels
        File.open(temp_stream, 'rb') do |f|
          if @zlib
            @pixels[i] = Zlib::Deflate.deflate(f.read, Zlib::DEFAULT_COMPRESSION)
          else
            @pixels[i] = f.read
          end
        end

        # remove the temp files
        FileUtils.rm temp_stream
        FileUtils.rm temp_image

        #puts "    lod #{i} is #{w} x #{h}"

        done = true if [w, h] == [1,1]
        
        w /= 2 if w > 1
        h /= 2 if h > 1
        i += 1
      end


      # set format fields
      format = @has_alpha ? GL_RGBA : GL_RGB
      @internal_format = format
      @format = format
      @type = GL_UNSIGNED_BYTE
    end
  end

  def initialize
    super "struct OpenGLTexture", 4, nil
  end
  
  def cook chunk, value, name

    # load the texture
    texture = Texture.new value

    # cook the texture data
    uint32 = TypeRegistry.lookup_type(:uint32)
    uint32.cook(chunk, texture.width, "#{name}.width")
    uint32.cook(chunk, texture.height, "#{name}.height")
    int32 = TypeRegistry.lookup_type(:int32)
    int32.cook(chunk, texture.internal_format, "#{name}.internal_format")
    int32.cook(chunk, texture.format, "#{name}.format")
    int32.cook(chunk, texture.type, "#{name}.type")
    int32.cook(chunk, texture.pixels.size, "#{name}.num_mips")

    mipmaps_chunk = Chunk.new
    texture.pixels.each_with_index do |p, i|
      image_chunk = Chunk.new
      image_chunk.push(p, "#{name} mipmap #{i}")
      mipmaps_chunk.add_pointer image_chunk
    end
    chunk.add_pointer mipmaps_chunk
  end

end
TypeRegistry.register(:OpenGLTexture, OpenGLTextureType.new, __FILE__)
