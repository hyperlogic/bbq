load 'level.dd'

children = []
children[0] = Child.new :numbers => [1,2,3]
children[1] = Child.new :numbers => [3,4]
children[2] = Child.new :numbers => []

$root = Level.new :children => children

	  