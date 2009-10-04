load 'app.dd'


BBQ.data do
  dark_gray = Color.build(:r => 0.1, :g => 0.1, :b => 0.1, :a => 1.0)
  red = Color.build(:r => 1.0, :g => 0.0, :b => 0.0, :a => 1.0)
  white = Color.build(:r => 1, :g => 1, :b => 1, :a => 1)

  App.build(:clear_color => red,
            :quad_color => white,
            :background => {:filename => 'logo.png', :has_alpha => false})
end
