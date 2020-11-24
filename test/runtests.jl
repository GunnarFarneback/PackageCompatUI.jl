using Test
using PackageCompatUI: compute_compat, get_julia_versions

@testset "compute_compat" begin
    versions = ["0.0.1", "0.0.2", "0.1.0", "0.1.1", "0.2.0",
                "1.0.0", "1.0.1", "1.0.2", "1.0.3",
                "1.1.0", "1.1.1", "1.2.0", "1.3.0", "1.3.1",
                "1.4.0", "1.4.1", "1.4.2",
                "1.5.0", "1.5.1", "1.5.2", "1.5.3"]

    @test compute_compat(versions, versions[1:1]) == "0.0.1"
    @test compute_compat(versions, versions[1:2]) == "0.0.1, 0.0.2"
    @test compute_compat(versions, versions[3:3]) == "=0.1.0"
    @test compute_compat(versions, versions[3:4]) == "0.1"
    @test compute_compat(versions, versions[3:5]) == "0.1, 0.2"
    @test compute_compat(versions, versions[6:6]) == "=1.0.0"
    @test compute_compat(versions, versions[6:9]) == "~1.0"
    @test compute_compat(versions, versions[6:10]) == "~1.0, =1.1.0"
    @test compute_compat(versions, versions[6:11]) == "~1.0, ~1.1"
    @test compute_compat(versions, versions[12:21]) == "1.2"
    @test compute_compat(versions, versions[14:21]) == "1.3.1"
    @test compute_compat(versions, versions[[1; 3; 4; 16:end]]) == "0.0.1, 0.1, 1.4.1"
end

@testset "get_julia_versions" begin
    # Julia versions as of 2020-11-15.
    julia_versions = ["1.0.0", "1.0.1", "1.0.2", "1.0.3", "1.0.4", "1.0.5",
                      "1.1.0", "1.1.1", "1.2.0", "1.3.0", "1.3.1",
                      "1.4.0", "1.4.1", "1.4.2",
                      "1.5.0", "1.5.1", "1.5.2", "1.5.3"]
    @test issubset(julia_versions, get_julia_versions())
end
