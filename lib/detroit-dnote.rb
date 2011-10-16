require 'detroit/tool'

module Detroit

  # Convenience constructor method.
  def DNote(options={})
    DNote.new(options)
  end

  # The Developmer's Notes tool goes through source files
  # and compiles a list of any labeled comments. Labels are
  # all-caps single word prefixes to a comment ending in a
  # colon and space.
  #
  # Common labels are `TODO`, `FIXME` and `OPTIMIZE`.
  #
  class DNote < Tool

    # not that this is necessary, but ...
    # def self.available(project)
    #  begin
    #    require 'dnote'
    #    require 'dnote/format'
    #    true
    #  rescue LoadError
    #    false
    #  end
    #end

    #
    DEFAULT_FILES = "**/*.rb"

    # Default note labels to looked for in source code.
    DEFAULT_LABELS = ['TODO', 'FIXME', 'OPTIMIZE', 'DEPRECATE']

    # Specific labels to document.
    attr_accessor :labels

    # File paths to search.
    attr_accessor :files

    # Exclude paths.
    attr_accessor :exclude

    # Ignore paths based on any part of pathname.
    attr_accessor :ignore

    # Title to use if template can use it.
    attr_accessor :title

    # Number of context lines to display.
    attr_accessor :lines

    # Output is either a file name with a clear extension to infer type
    # or a list of such file names, or a hash mapping file name to type.
    #
    #   output: NOTES.rdoc
    #
    #   output:
    #     - NOTES.rdoc
    #     - site/notes.html
    #
    #   output:
    #     NOTES: markdown
    #     site/notes.html: html
    #
    # Recognized formats include `xml`, `html` and `rdoc` among others.
    attr_accessor :output


    #  A S S E M B L Y  S T A T I O N S

    # Attach document method to assembly station.
    def station_document
      document
    end

    # Attach reset method to assembly station.
    def station_reset
      reset
    end

    # Attach purge method to assembly station.
    def station_purge
      purge
    end


    #  S E R V I C E  M E T H O D S

    # Check the output file and see if they are older than
    # the input files.
    #
    # @return [Boolean] whether output is up-to-date
    def current?
      output_mapping.each do |file, format|
        return false if outofdate?(file, *dnote_session.files)
      end
      "DNotes are current (#{output})"
    end

    # Generate notes documents.
    def document
      session = dnote_session

      output_mapping.each do |file, format|
        #next unless verify_format(format)

        mkdir_p(File.dirname(file))

        session.output = file
        session.format = format
        session.run

        report "Updated #{file.sub(Dir.pwd+'/','')}"
      end
    end

    # Reset output files, marking them as out-of-date.
    def reset
      output.each do |file, format|
        if File.exist?(file)
          utime(0,0,file)
          report "Marked #{file} as out-of-date."
        end
      end
    end

    # Remove output files.
    def purge
      output.each do |file, format|
        if File.exist?(file)
          rm(file)
          report "Removed #{file}"
        end
      end
    end

  private

    # Convert output into a hash of `file => format`.
    #++
    # TODO: apply_naming_policy ?
    #--
    def output_mapping
      @output_mapping ||= (
        hash = {}
        case output
        when Array
          output.each do |path|
            hash[path] = format(path)
          end
        when String
          hash[output] = format(output)
        when Hash
          hash = output
        end
        hash
      )
    end

    #
    def format(file)
      type = File.extname(file).sub('.','')
      type = DEFAULT_FORMAT if type.empty?
      type
    end

    #
    def dnote_session
      ::DNote::Session.new do |s|
        s.paths   = files
        s.exclude = exclude
        s.ignore  = ignore
        s.labels  = labels
        s.title   = title
        s.context = lines
        s.dryrun  = trial?
      end
    end

    #
    def initialize_requires
      require 'dnote'
      require 'dnote/format'
    end

    #
    def initialize_defaults
      @files   = DEFAULT_FILES
      @output  = project.log + 'dnotes.html'
      @labels  = nil #DEFAULT_LABELS
    end

  end

end
