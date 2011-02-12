require 'spec_helper'

require 'rserve/simpler'


describe 'rserve connection with simpler' do
  xit 'is quiet on startup' do
    @r = Rserve::Simpler.new
  end
end

describe 'rserve connection with simpler additions' do

  before do
    @r = Rserve::Simpler.new 
  end

  after do
    @r.close
  end

  it 'converses with R using strings' do
  # both sides speak native
    ok @r.connected?
    reply = @r.converse "mean(c(1,2,3))"
    @r.converse("mean(c(1,2,3))").is 2.0
  end

  it 'converses with R using arrays and numbers' do
    @r.converse("cor(a,b)", :a => [1,2,3], :b => [4,5,6]).is 1.0
    @r.converse(:a => [1,2,3], :b => [4,5,6]) { "cor(a,b)" }.is 1.0
    @r.converse(:a => 3) { "mean(a)" }.is 3.0
  end

  it 'can converse in sentences' do
    (mean, cor) = @r.converse("mean(a)", "cor(a,b)", :a => [1,2,3], :b => [4,5,6])
    mean.is 2.0
    cor.is 1.0
  end

  it 'has a prompt-like syntax' do
    reply = @r >> "mean(c(1,2,3))"
    reply.is 2.0
    reply = @r.>> "cor(a,b)", a: [1,2,3], b: [1,2,3]
    reply.is 1.0
  end

  it "commands R (giving no response but 'true')" do
    @r.command(:a => [1,2,3], :b => [4,5,6]) { "z = cor(a,b)" }.is true
    @r.converse("z").is 1.0
  end

  xit "returns the REXP if to_ruby raises an error" do
    flunk
  end

end

if RUBY_VERSION > '1.9'

  # TODO: write these compatible for 1.8

  describe 'rserve with DataFrame convenience functions' do

    Row = Struct.new(:fac1, :var1, :res1)

    before do
      @r = Rserve::Simpler.new 
      @hash = {:fac1 => [1,2,3,4], :var1 => [4,5,6,7], :res1 => [8,9,10,11]}
      @colnames = %w(fac1 var1 res1).map(&:to_sym)
      @ar_of_structs = [Row.new(1,4,8), Row.new(2,5,9), Row.new(3,6,10), Row.new(4,7,11)]
    end

    after do
      @r.close
    end

    it 'gives hashes a .to_dataframe method' do
      # only need to set the colnames with Ruby 1.8 (unless using OrderedHash)
      df1 = Rserve::DataFrame.new(@hash) 
      df2 = @hash.to_dataframe
      df2.colnames.is @colnames
      df1.is df2
      df2.colnames.is @colnames
      df2.rownames.is nil
      df2.rownames = [1,2,3,4]
      df2.rownames.is [1,2,3,4]
    end

    it 'converts an array of parallel structs into a dataframe' do
      df = Rserve::DataFrame.from_structs( @ar_of_structs )
      df.is @hash.to_dataframe
    end

    it 'accepts simple dataframes when conversing with R' do
      @r.converse(:df => @hash.to_dataframe) { "names(df)" }.is %w(fac1 var1 res1)
    end

    it 'accepts dataframes with rownames when conversing with R' do
      rownames = [11,12,13,14]
      @r.converse(:df => @hash.to_dataframe(rownames)) { "row.names(df)" }.is rownames.map(&:to_s)
      rownames = %w(row1 row2 row3 row4)
      @r.converse(:df => @hash.to_dataframe(rownames)) { "row.names(df)" }.is rownames
    end
  end

end
