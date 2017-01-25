# Author: Cedric St-Jean
# with some code taken from NBInclude.jl, by Steven G. Johnson
# __precompile__()

module NBTesting
using JSON

is_skip(line) = startswith(line, "#NBSKIP") || startswith(line, "# NBSKIP")

function nbtranslate(path::AbstractString;
                     outfile_name = "NBTest_" * splitext(path)[1] * ".jl")
    _, ext = splitext(path)
    @assert ext == ".ipynb" "nbtranslate only accepts notebook files (.ipynb)"

    # sleep a bit to process file requests from other nodes
    nprocs()>1 && sleep(0.005)
    nb = open(JSON.parse, path, "r")

    # check for an acceptable notebook:
    nb["nbformat"] == 4 || error("unrecognized notebook format ", nb["nbformat"])
    lang = lowercase(nb["metadata"]["language_info"]["name"])
    lang == "julia" || error("notebook is for unregognized language $lang")

    shell_or_help = r"^\s*[;?]" # pattern for shell command or help
    
    open(outfile_name, "w") do outfile
        for (counter, cell) in enumerate(nb["cells"])
            if cell["cell_type"] == "code" && !isempty(cell["source"])
                s = join(cell["source"])
                isempty(strip(s)) && continue # Jupyter doesn't number empty cells
                ismatch(shell_or_help, s) && continue
                cellnum = string(counter)
                
                lines = split(s, "\n")
                if !is_skip(lines[1])
                    write(outfile, string("# Cell #", cellnum, "\n"))
                end
                for line in lines
                    if is_skip(line) break end
                    write(outfile, line)
                    write(outfile, "\n")
                end
                write(outfile, "\n")
            end
        end
    end
    return outfile_name
end



end # module
