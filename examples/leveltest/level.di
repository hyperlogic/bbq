load 'level.dd'

BBQ.data do
  Level.build(:children => [Child.build(:numbers => [1,2]),
                            Child.build(:numbers => [1,2,3]),
                            Child.build(:numbers => [1,2,3,4])],
              :bytes => [0x0a, 0x0b, 0x0c])
end

	  
