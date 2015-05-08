require 'transair'

describe Transair do
  describe "GET /strings/:key/:version" do
    it "returns the string with the given key and version" do
      get '/strings/foo.bar/xxx'
    end
  end
end
