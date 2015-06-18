module CrudTest
  define_method 'test_bot: first_test' do
    assert true
  end

  define_method 'test_bot: second_test' do
    assert_equal 'normal@agilestyle.com', user.email
    assert true
  end

  define_method 'test_bot: last_test' do
    assert_equal 'normal@agilestyle.com', user.email
    assert true
  end

end
