#----------------------------------------------------------#
# Input validation tests -----
#----------------------------------------------------------#

testthat::test_that(
  "select_unclassified_taxa() validates vec_community_taxa type",
  {
    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = 123,
        data_classification_table = data_classification_table
      ),
      regexp = "vec_community_taxa should be"
    )

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = NULL,
        data_classification_table = data_classification_table
      ),
      regexp = "vec_community_taxa should be"
    )

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = list("Quercus"),
        data_classification_table = data_classification_table
      ),
      regexp = "vec_community_taxa should be"
    )
  }
)

testthat::test_that(
  "select_unclassified_taxa() rejects empty vec_community_taxa",
  {
    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = base::character(0),
        data_classification_table = data_classification_table
      ),
      regexp = "vec_community_taxa should be"
    )
  }
)

testthat::test_that(
  "select_unclassified_taxa() validates classification table type",
  {
    vec_taxa <- c("Quercus", "Pinus")

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = "not_a_df"
      ),
      regexp = "data_classification_table should be a data frame"
    )

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = base::list(sel_name = "Quercus")
      ),
      regexp = "data_classification_table should be a data frame"
    )
  }
)

testthat::test_that(
  "select_unclassified_taxa() requires sel_name column",
  {
    vec_taxa <- c("Quercus", "Pinus")

    data_classification_invalid <-
      data.frame(taxon_name = c("Quercus", "Pinus"))

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_invalid
      ),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "select_unclassified_taxa() rejects duplicate sel_name",
  {
    vec_taxa <- c("Quercus", "Pinus")

    data_classification_duplicates <-
      data.frame(sel_name = c("Quercus", "Quercus", "Pinus"))

    testthat::expect_error(
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_duplicates
      ),
      regexp = "duplicate"
    )
  }
)


#----------------------------------------------------------#
# Output structure tests -----
#----------------------------------------------------------#

testthat::test_that(
  "select_unclassified_taxa() returns a character vector",
  {
    vec_taxa <-
      c("Quercus", "Pinus", "Betula")

    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_type(res_unclassified_taxa, "character")
  }
)

testthat::test_that(
  "select_unclassified_taxa() returns empty vector if all classified",
  {
    vec_taxa <-
      c("Quercus", "Pinus")

    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus", "Betula"))

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_length(res_unclassified_taxa, 0)
    testthat::expect_type(res_unclassified_taxa, "character")
  }
)


#----------------------------------------------------------#
# Functional correctness tests -----
#----------------------------------------------------------#

testthat::test_that(
  "select_unclassified_taxa() identifies missing taxa correctly",
  {
    vec_taxa <-
      c("Quercus", "Pinus", "Betula", "Alnus")

    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_length(res_unclassified_taxa, 2)
    testthat::expect_true("Betula" %in% res_unclassified_taxa)
    testthat::expect_true("Alnus" %in% res_unclassified_taxa)
    testthat::expect_false("Quercus" %in% res_unclassified_taxa)
    testthat::expect_false("Pinus" %in% res_unclassified_taxa)
  }
)

testthat::test_that(
  "select_unclassified_taxa() deduplicates vec_community_taxa",
  {
    vec_taxa <-
      c("Betula", "Betula", "Quercus")

    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    # Betula appears twice in input but should appear once in output
    testthat::expect_length(res_unclassified_taxa, 1)
    testthat::expect_equal(res_unclassified_taxa, "Betula")
  }
)

testthat::test_that(
  "select_unclassified_taxa() returns all taxa when none classified",
  {
    vec_taxa <-
      c("Betula", "Alnus", "Salix")

    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_length(res_unclassified_taxa, 3)
    testthat::expect_true(
      base::all(c("Betula", "Alnus", "Salix") %in% res_unclassified_taxa)
    )
  }
)

testthat::test_that(
  "select_unclassified_taxa() works with extra columns in table",
  {
    vec_taxa <-
      c("Quercus", "Betula")

    data_classification_table <-
      data.frame(
        sel_name = c("Quercus", "Pinus"),
        resolution = c("genus", "genus"),
        family = c("Fagaceae", "Pinaceae")
      )

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_length(res_unclassified_taxa, 1)
    testthat::expect_equal(res_unclassified_taxa, "Betula")
  }
)


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that(
  "select_unclassified_taxa() works with a single unclassified taxon",
  {
    vec_taxa <- "Betula"

    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_length(res_unclassified_taxa, 1)
    testthat::expect_equal(res_unclassified_taxa, "Betula")
  }
)

testthat::test_that(
  "select_unclassified_taxa() works with a single classified taxon",
  {
    vec_taxa <- "Quercus"

    data_classification_table <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_length(res_unclassified_taxa, 0)
    testthat::expect_type(res_unclassified_taxa, "character")
  }
)

testthat::test_that(
  "select_unclassified_taxa() works at moderate scale",
  {
    vec_taxa <-
      stringr::str_glue("taxon_{base::seq_len(1000)}")

    # Classify the first 800; 200 should be missing
    data_classification_table <-
      data.frame(
        sel_name = stringr::str_glue("taxon_{base::seq_len(800)}")
      )

    res_unclassified_taxa <-
      select_unclassified_taxa(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_classification_table
      )

    testthat::expect_length(res_unclassified_taxa, 200)
    testthat::expect_type(res_unclassified_taxa, "character")
  }
)
