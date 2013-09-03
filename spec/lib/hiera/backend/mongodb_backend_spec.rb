require 'spec_helper'
require 'hiera/backend/mongodb_backend'

class Hiera
  module Backend
    describe Mongodb_backend do
      before do
        Config.load({'mongodb'=>'asdfas'})
        Hiera.stub :debug
        Hiera.stub :warn

        @collection_mock = double('collection').as_null_object
        Mongodb_backend.should_receive(:load_collection).any_number_of_times.and_return(@collection_mock)

        @backend = Mongodb_backend.new
      end

      describe '#initialize' do
        it 'should print debug through Hiera' do
          Hiera.should_receive(:debug).with('Hiera MongoDB backend starting')
          Mongodb_backend.new
        end
      end

      describe '#lookup' do
        it 'should look for data in all sources' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return(nil)
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'two', 'key' => 'awesomeKey'}).and_return(nil)

          @backend.lookup('awesomeKey', {}, nil, :priority)
        end

        it 'should pick data earliest source that has it for priority searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return({'value'=>'a'})

          @backend.lookup('awesomeKey', {}, nil, :priority).should == 'a'
        end

        it 'should return nil for missing path/value' do
          Backend.should_receive(:datasources).with(:scope, :override).and_yield(['one'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return(nil)

          @backend.lookup('awesomeKey', :scope, :override, :priority)
        end

        it 'should build an array of all data sources for array searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return({'value'=>'answer'})
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'two', 'key' => 'awesomeKey'}).and_return({'value'=>'answer'})

          @backend.lookup('awesomeKey', {}, nil, :array).should == ['answer', 'answer']
        end

        it 'should ignore empty hash of data sources for hash searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return({'value'=>{}})
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'two', 'key' => 'awesomeKey'}).and_return({'value'=>{'a'=>'answer'}})

          @backend.lookup('awesomeKey', {}, nil, :hash).should == {'a'=>'answer'}
        end

        it 'should build a merged hash of data sources for hash searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return({'value'=>{'a'=>'answer'}})
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'two', 'key' => 'awesomeKey'}).and_return({'value'=>{'b'=>'answer', 'a'=>'wrong'}})

          @backend.lookup('awesomeKey', {}, nil, :hash).should == {'a'=>'answer', 'b'=>'answer'}
        end

        it 'should fail when trying to << a Hash' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return({'value'=>['a'=>'answer']})
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'two', 'key' => 'awesomeKey'}).and_return({'value'=>{'a'=>'answer'}})

          expect {
            @backend.lookup('awesomeKey', {}, nil, :array)
          }.to raise_error(Exception, 'Hiera type mismatch: expected Array and got Hash')
        end

        it 'should fail when trying to merge an Array' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return({'value'=>{'a'=>'answer'}})
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'two', 'key' => 'awesomeKey'}).and_return({'value'=>['a'=>'answer']})

          expect {
            @backend.lookup('awesomeKey', {}, nil, :hash)
          }.to raise_error(Exception, 'Hiera type mismatch: expected Hash and got Array')
        end

        it 'should parse the answer for scope variables' do
          Backend.should_receive(:datasources).and_yield(['one'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'awesomeKey'}).and_return({'value'=>'test_%{rspec}'})

          @backend.lookup('awesomeKey', {'rspec'=>'test'}, nil, :priority).should == 'test_test'
        end

        it 'should retain the data types found in value' do
          Backend.should_receive(:datasources).exactly(3).and_yield(['one'])

          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'stringval'}).and_return({'value'=>'string'})
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'boolval'}).and_return({'value'=>true})
          @collection_mock.should_receive(:find_one).once.ordered.with({'source' => 'one', 'key' => 'numericval'}).and_return({'value'=>1})

          @backend.lookup('stringval', {}, nil, :priority).should == 'string'
          @backend.lookup('boolval', {}, nil, :priority).should == true
          @backend.lookup('numericval', {}, nil, :priority).should == 1
        end
      end
    end
  end
end
