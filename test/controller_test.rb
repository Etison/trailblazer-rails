require 'test_helper'

ActionController::TestCase.class_eval do
  setup do
    @routes = Rails.application.routes
  end
end

class GenericResponderTest < ActionController::TestCase
  tests SongsController

  setup do
    @routes = Rails.application.routes
  end

  test "Create with params" do
    post :create_with_params, {song: {title: "You're Going Down", length: 120}}
    assert_response 302

    song = Song.last
    assert_equal "A Beautiful Indifference", song.title
    assert_equal nil, song.length # params overwritten from controller.
  end
end

# overriding Controller#process_params.
class ProcessParamsTest < ActionController::TestCase
  tests BandsController

  setup do
    @routes = Rails.application.routes
  end

  test "Create with overridden #process_params" do
    post :create, band: {name: "Kreator"}
    assert_redirected_to band_path(Band.last)

    band = Band.last
    assert_equal "Kreator", band.name
    assert_equal "Essen", band.locality
  end
end



class ControllerRunTest < ActionController::TestCase
  tests BandsController

  # JS (url-encoded, etc) assumes is_document: false
  test "[html/valid]" do
    put :update, {id: 1, band: {name: "Nofx"}}
    assert_equal "no block: Band::Create, Nofx, Essen, Band::Create", response.body
  end

  # JS (url-encoded, etc) assumes is_document: false
  test "#run with format: :js" do
    put :update, id: 1, band: {name: "Nofx"}, format: :js
    assert_equal "no block: Band::Create, Nofx, Essen, Band::Create", response.body
  end


  test "[html/valid] with builds" do
    put :update, {id: 1, band: {name: "Nofx"}, admin: true}
    assert_equal "no block: Band::Create::Admin, Nofx [ADMIN], Essen, Band::Create::Admin", response.body
  end

  test "with block, valid" do
    put :update_with_block, {id: 1, band: {name: "Nofx"}}
    assert_equal "[valid] with block: Nofx, Essen", response.body
  end

  test "with block, error" do
    put :update_with_block, {id: 1, band: {name: ""}}
    assert_equal "[invalid] with block: Band::Create, {:name=>[\"can't be blank\"]}, Essen", response.body
  end

  test "with block [html/invalid]" do
    put :update_with_block, {id: 1, band: {name: ""}}
  end
end

#present.
class ControllerPresentTest < ActionController::TestCase
  tests BandsController

  # let (:band) { }

  test "#present" do
    band = Band::Create.(band: {name: "Nofx"}).model

    get :show, id: band.id

    assert_equal "bands/show: Band::Update,Band,Band::Update,Essen,nil", response.body
  end

  # TODO: this implicitely tests builds. maybe have separate test for that?
  test "#present [JSON]" do
    band = Band::Create.(band: {name: "Nofx"}).model

    get :show, id: band.id, format: :json
    assert_equal "{\"name\":\"Nofx\"}", response.body
  end
end

#collection
class ControllerCollectionTest < ActionController::TestCase
  tests BandsController

  # let (:band) { }

  test "#collection" do
    Band.destroy_all
    Band::Create.(band: {name: "Nofx"})
    Band::Create.(band: {name: "Ramones"})


    get :index

    assert_equal "bands/index.html: Nofx Ramones \n", response.body
  end
end

# #form.
class ControllerFormTest < ActionController::TestCase
  tests BandsController

  test "#form" do
    get :new
    assert_select "form input#band_name"
    assert response.body =~ /<a>Sydney<\/a>/ # prepopulate!
    assert_select "b", "Band,true,Band::Create,true,Essen"
  end

  test "#form with builder" do
    get :new, admin: true

    assert_select "b", "Band,true,Band::Create::Admin,true,Essen"
  end
end

