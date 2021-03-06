require "spec_helper"
require "foreman/engine"

describe "Foreman::Engine" do
  subject { Foreman::Engine.new("Procfile") }

  describe "initialize" do
    describe "without an existing Procfile" do
      it "raises an error" do
        lambda { subject }.should raise_error
      end
    end

    describe "with a Procfile" do
      before { write_procfile }

      it "reads the processes" do
        subject.processes["alpha"].command.should == "./alpha"
        subject.processes["bravo"].command.should == "./bravo"
      end
    end

    describe "with a deprecated Procfile" do
      before do
        File.open("Procfile", "w") do |file|
          file.puts "name command"
        end
      end

      it "should print a deprecation warning" do
        mock(subject).warn_deprecated_procfile!
        subject.processes.length.should == 1
      end
    end
  end

  describe "start" do
    it "forks the processes" do
      write_procfile
      mock(subject).fork(subject.processes["alpha"], {})
      mock(subject).fork(subject.processes["bravo"], {})
      mock(subject).watch_for_termination
      subject.start
    end

    it "handles concurrency" do
      write_procfile
      mock(subject).fork_individual(subject.processes["alpha"], 1, 5000)
      mock(subject).fork_individual(subject.processes["alpha"], 2, 5001)
      mock(subject).fork_individual(subject.processes["bravo"], 1, 5100)
      mock(subject).watch_for_termination
      subject.start(:concurrency => "alpha=2")
    end
  end

  describe "execute" do
    it "runs the processes" do
      write_procfile
      mock(subject).fork(subject.processes["alpha"], {})
      mock(subject).watch_for_termination
      subject.execute("alpha")
    end
  end
end
