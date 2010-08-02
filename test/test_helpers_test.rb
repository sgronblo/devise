require 'test/test_helper'

class TestHelpersTest < ActionController::TestCase
  tests UsersController
  include Devise::TestHelpers

  test "redirects if attempting to access a page unauthenticated" do
    get :show
    assert_redirected_to "/users/sign_in?unauthenticated=true"
  end

  test "redirects if attempting to access a page with a unconfirmed account" do
    swap Devise, :confirm_within => 0 do
      sign_in create_user
      get :show
      assert_redirected_to "/users/sign_in?unconfirmed=true"
    end
  end

  test "does not redirect with valid user" do
    user = create_user
    user.confirm!

    sign_in user
    get :show
    assert_response :success
  end

  test "redirects if valid user signed out" do
    user = create_user
    user.confirm!

    sign_in user
    get :show

    sign_out user
    get :show
    assert_redirected_to "/users/sign_in?unauthenticated=true"
  end

  test "defined Warden after_authentication callback should be called when sign_in is called" do
    Warden::Manager.after_authentication do |user, auth, opts|
      @after_authentication_called = true
    end
    user = create_user
    user.confirm!

    sign_in user
    assert_equal true, @after_authentication_called
  end

  test "defined Warden before_logout callback should be called when sign_out is called" do
    Warden::Manager.before_logout do |user, auth, opts|
      @before_logout_called = true
    end
    user = create_user
    user.confirm!

    sign_in user
    sign_out user
    assert_equal true, @before_logout_called
  end

  test "the user parameter in warden after_authentication callbacks should not be nil" do
    Warden::Manager.after_authentication do |user, auth, opts|
      assert_not_nil user
    end
    user = create_user
    user.confirm!

    sign_in user
  end

  # Not sure if the warden manager needs to be reset after the test cases which modify
  # the callbacks, maybe the original values can just be restored or the warden manager
  # class definition file can be reloaded.
  test "the user parameter in warden before_logout callbacks should not be nil" do
    Warden::Manager.before_logout do |user, auth, opts|
      assert_not_nil user
    end
    user = create_user
    user.confirm!

    sign_in user
    sign_out user
  end

  test "allows to sign in with different users" do
    first_user = create_user
    first_user.confirm!

    sign_in first_user
    get :show
    assert_equal first_user.id.to_s, @response.body
    sign_out first_user

    second_user = create_user
    second_user.confirm!

    sign_in second_user
    get :show
    assert_equal second_user.id.to_s, @response.body
  end
end
