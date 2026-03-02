#----------------------------------------------------------#
# Input validation tests -----
#----------------------------------------------------------#

testthat::test_that(
  "get_taxa_without_classification() validates vec_community_taxa type",
  {
    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = 123,
        data_classification_table = data_cls
      ),
      regexp = "vec_community_taxa should be"
    )

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = NULL,
        data_classification_table = data_cls
      ),
      regexp = "vec_community_taxa should be"
    )

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = list("Quercus"),
        data_classification_table = data_cls
      ),
      regexp = "vec_community_taxa should be"
    )
  }
)

testthat::test_that(
  "get_taxa_without_classification() rejects empty vec_community_taxa",
  {
    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = base::character(0),
        data_classification_table = data_cls
      ),
      regexp = "vec_community_taxa should be"
    )
  }
)

testthat::test_that(
  "get_taxa_without_classification() validates classification table type",
  {
    vec_taxa <- c("Quercus", "Pinus")

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = "not_a_df"
      ),
      regexp = "data_classification_table should be a data frame"
    )

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = base::list(sel_name = "Quercus")
      ),
      regexp = "data_classification_table should be a data frame"
    )
  }
)

testthat::test_that(
  "get_taxa_without_classification() requires sel_name column",
  {
    vec_taxa <- c("Quercus", "Pinus")

    data_bad <-
      data.frame(taxon_name = c("Quercus", "Pinus"))

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_bad
      ),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "get_taxa_without_classification() rejects duplicate sel_name",
  {
    vec_taxa <- c("Quercus", "Pinus")

    data_dup <-
      data.frame(sel_name = c("Quercus", "Quercus", "Pinus"))

    testthat::expect_error(
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_dup
      ),
      regexp = "duplicate"
    )
  }
)


#----------------------------------------------------------#
# Output structure tests -----
#----------------------------------------------------------#

testthat::test_that(
  "get_taxa_without_classification() returns a character vector",
  {
    vec_taxa <-
      c("Quercus", "Pinus", "Betula")

    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_type(res, "character")
  }
)

testthat::test_that(
  "get_taxa_without_classification() returns empty vector if all classified",
  {
    vec_taxa <-
      c("Quercus", "Pinus")

    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus", "Betula"))

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_length(res, 0)
    testthat::expect_type(res, "character")
  }
)


#----------------------------------------------------------#
# Functional correctness tests -----
#----------------------------------------------------------#

testthat::test_that(
  "get_taxa_without_classification() identifies missing taxa correctly",
  {
    vec_taxa <-
      c("Quercus", "Pinus", "Betula", "Alnus")

    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_length(res, 2)
    testthat::expect_true("Betula" %in% res)
    testthat::expect_true("Alnus" %in% res)
    testthat::expect_false("Quercus" %in% res)
    testthat::expect_false("Pinus" %in% res)
  }
)

testthat::test_that(
  "get_taxa_without_classification() deduplicates vec_community_taxa",
  {
    vec_taxa <-
      c("Betula", "Betula", "Quercus")

    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    # Betula appears twice in input but should appear once in output
    testthat::expect_length(res, 1)
    testthat::expect_equal(res, "Betula")
  }
)

testthat::test_that(
  "get_taxa_without_classification() returns all taxa when none classified",
  {
    vec_taxa <-
      c("Betula", "Alnus", "Salix")

    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_length(res, 3)
    testthat::expect_true(
      base::all(c("Betula", "Alnus", "Salix") %in% res)
    )
  }
)

testthat::test_that(
  "get_taxa_without_classification() works with extra columns in table",
  {
    vec_taxa <-
      c("Quercus", "Betula")

    data_cls <-
      data.frame(
        sel_name = c("Quercus", "Pinus"),
        resolution = c("genus", "genus"),
        family = c("Fagaceae", "Pinaceae")
      )

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_length(res, 1)
    testthat::expect_equal(res, "Betula")
  }
)


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that(
  "get_taxa_without_classification() works with a single unclassified taxon",
  {
    vec_taxa <- "Betula"

    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_length(res, 1)
    testthat::expect_equal(res, "Betula")
  }
)

testthat::test_that(
  "get_taxa_without_classification() works with a single classified taxon",
  {
    vec_taxa <- "Quercus"

    data_cls <-
      data.frame(sel_name = c("Quercus", "Pinus"))

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_length(res, 0)
    testthat::expect_type(res, "character")
  }
)

testthat::test_that(
  "get_taxa_without_classification() works at moderate scale",
  {
    vec_taxa <-
      base::paste0("taxon_", base::seq_len(1000))

    # Classify the first 800; 200 should be missing
    data_cls <-
      data.frame(
        sel_name = base::paste0("taxon_", base::seq_len(800))
      )

    res <-
      get_taxa_without_classification(
        vec_community_taxa = vec_taxa,
        data_classification_table = data_cls
      )

    testthat::expect_length(res, 200)
    testthat::expect_type(res, "character")
  }
)
