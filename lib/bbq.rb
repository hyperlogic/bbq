# bbq

DEBUG_COOK = false

require 'ostruct'

class OpenStruct
  def build hash
    hash.each do |key, value|
      self.send("#{key}=", value)
    end
    self
  end
end

require 'bbq/header'
require 'bbq/data'
require 'bbq/chunk'
require 'bbq/types'
require 'bbq/struct'
require 'bbq/texture_type'
require 'bbq/enum'




