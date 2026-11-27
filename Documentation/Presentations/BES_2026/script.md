# BES 2026 recorded talk: script

Narration for the 15-minute recorded talk at the British Ecological Society Annual Meeting 2026 (online programme). The same text is in the speaker notes of `index.qmd` (press `S` in the HTML deck for the speaker view). Generated from one source, so the notes, this script and `transcript.txt` always match.

Timing assumes 130 words per minute (BES asks presenters to speak slower than in person) plus about 5 seconds per slide for fragments and animations.

## Timing

| Slide | Content | Words | Time | Cumulative |
| --- | --- | ---: | ---: | ---: |
| 00 | Title | 79 | 0:41 | 0:41 |
| 01 | ORACLE boots | 48 | 0:27 | 1:08 |
| 02a | The question | 78 | 0:41 | 1:49 |
| 02 | Query: partition co-occurrence | 36 | 0:22 | 2:11 |
| 03 | Data: VegVault | 64 | 0:35 | 2:46 |
| 04 | Preparing community and climate streams | 79 | 0:41 | 3:27 |
| 05 | Model core | 89 | 0:46 | 4:13 |
| 06 | Variance decomposition | 56 | 0:31 | 4:44 |
| 07 | Three analysis axes | 24 | 0:16 | 5:00 |
| 08a | Section: spatial scale | 6 | 0:08 | 5:08 |
| 08 | Spatial results | 138 | 1:09 | 6:17 |
| 9a | Section: taxonomic scale | 8 | 0:09 | 6:26 |
| 09 | Spatial pattern and taxonomic resolution | 71 | 0:38 | 7:04 |
| 10a | Section: temporal scale | 4 | 0:07 | 7:11 |
| 10 | Is the association signal stable through time? | 54 | 0:30 | 7:41 |
| 11 | Temporal trajectories | 76 | 0:40 | 8:21 |
| 11a | Section: matrix scale | 17 | 0:13 | 8:34 |
| 11b | Bigger matrix, more association | 115 | 0:58 | 9:32 |
| 12 | Paleo predictions | 83 | 0:43 | 10:15 |
| 13 | Take-home messages | 140 | 1:10 | 11:25 |
| 14 | Termination | 14 | 0:11 | 11:36 |
| 15 | Presenter | 52 | 0:29 | 12:05 |
| 16 | Presentation availability | 32 | 0:20 | 12:25 |
| 17 | Final slide | 16 | 0:12 | 12:37 |
| **Total** | | **1379** | | **12:37** |

## Narration

### Slide 00: Title

Hello and welcome to my talk! I would like to try something a little different: science should be serious, but also a bit fun. So please close your eyes and imagine that we are on a spaceship, and our goal is to examine the vegetation of a strange planet called Earth. We will use the ship's supercomputer, ORACLE. All the data, analyses and results you will see are real. The supercomputer is not; it is only a narrative device.

### Slide 01: ORACLE boots

Welcome, fellow scientists, you may open your eyes! I am Ondřej Mottl, the chief researcher on this ship. We have about 15 minutes with ORACLE, the Observational Runtime for Analysis of Community-Level Ecology, to explore the vegetation of planet Earth. ORACLE has introduced itself, so let's get started.

### Slide 02a: The question

The question of this talk is: is there a scale dependence in the amount of unexplained variation that structures vegetation since the Last Glacial Maximum? We know that climate and spatial processes explain a lot, but I am interested in what remains, which could partly reflect biotic interactions: competition, facilitation, or shared pollinators and herbivores. We would expect this part to change with scale; for example, interactions should be easier to detect at local than at continental scales.

### Slide 02: Query: partition co-occurrence

So, ORACLE: is there a scale dependence? ORACLE proposes to partition the observed plant co-occurrence into three components: spatial structure, shown in blue throughout; the climate response, in yellow; and the residual species-species association, in purple.

### Slide 03: Data: VegVault

For the data we use VegVault, an open database that combines vegetation plots, fossil pollen records, contemporary and past climate, and functional traits. The database is global, but here we focus on the Northern Hemisphere, with the strongest coverage in North America and Europe, plus Asia. VegVault is described in a paper in Scientific Data, and you can reach it through the QR code.

### Slide 04: Preparing community and climate streams

Next, the data need processing; I will only mention the main steps. Pollen counts are turned into proportions and interpolated to 500-year steps, carrying the age uncertainty from the age-depth models. Taxonomy is harmonised to the GBIF backbone, so we can choose the resolution, genus or family. For climate, we use CHELSA bioclimatic variables, drop constant predictors, keep a non-collinear set and interpolate them to the same 500-year steps. Finally, we keep only units with enough samples and cores.

### Slide 05: Model core

For the model we use sjSDM, a scalable joint species distribution model that runs on graphics cards and so copes with very large datasets. For the spatial models, the regularisation of each model is selected by cross-validation that holds out whole sites. Now a little maths: the response is presence or absence. The linear predictor has an intercept; the climate predictors and their interaction with time, because the response to climate may change through time; Moran eigenvector maps, which absorb spatial and temporal autocorrelation; and the residual species-species association.

### Slide 06: Variance decomposition

Once a model is fitted, we decompose its explained variance into climate, space and association. In this example, about 60% goes to climate, 30% to space and 10% to association. We can also merge the three numbers into one colour on this colour triangle: the more purple a point, the more residual association in that model.

### Slide 07: Three analysis axes

We split the analysis along three axes: spatial scale, from local to continental; taxonomic resolution; and time, from the Last Glacial Maximum to now.

### Slide 08a: Section: spatial scale

Let's start with the spatial axis.

### Slide 08: Spatial results

ORACLE, show us how the association signal changes from local to continental. The map shows the nested units: continental models use all data from a continent, regional models a subset, and local models an even smaller one, and each gets its own model. In the results, the x-axis runs from local on the left to continental on the right, and the y-axis is the share of explained variance that goes to association. Each point is one model, coloured by the colour triangle, and the purple bar is the median.

Surprisingly, the association signal does not get stronger at the local scale; if anything, the median rises toward the continental scale, although there are only three continental models. There is a lot of variation between units, and the colours sit between climate and association, so climate stays important everywhere.

### Slide 9a: Section: taxonomic scale

Now, what if we add the taxonomic axis?

### Slide 09: Spatial pattern and taxonomic resolution

We expected that a coarser taxonomic resolution would change the spatial pattern. Here are the same units modelled at genus level, at family level, and with taxa replaced by functional types derived from their traits. Coarser groups shift the whole pattern down: genera have the highest association shares, then families, then functional types. But the spatial pattern hardly changes: at no resolution is the association signal stronger at the local scale.

### Slide 10a: Section: temporal scale

Finally, the temporal axis.

### Slide 10: Is the association signal stable through time?

Is the association signal stable through time? So far we used the whole fossil record at once. Now we split it into 500-year slices and fit a separate model to each slice. For each slice we also compute classic network diagnostics on the bipartite network of taxa and sites, such as connectance and modularity.

### Slide 11: Temporal trajectories

Here are the results for North America, Europe and Asia. Each step of the animation is one 500-year slice with its own model; the colours show the variance decomposition, and the green line is the modularity of the community network. Modularity changes through time, for example with the drop around 10,000 years ago in Europe, which may be connected to rapid climate change. The variance decomposition, in contrast, is surprisingly stable through time on all continents.

### Slide 11a: Section: matrix scale

Before we put the pieces together, ORACLE flagged one more thing: the size of the models themselves.

### Slide 11b: Bigger matrix, more association

Every point here is one fossil-pollen spatial model. The x-axis is the number of taxa in the model, on a log scale; the y-axis is the share of explained variance that goes to association. The more taxa a model holds, the larger its association share, at every taxonomic resolution. Taxon number alone explains about two thirds of the variation, and the relationship also holds on a deviance scale and in the models fitted without a penalty on the association term.

Ecologically this makes sense: a taxon modelled with fifty others has more partners that carry information about it. But it means that the amount of association cannot be compared directly between models of different size.

### Slide 12: Paleo predictions

What else can these models do? Like any species distribution model, they can predict. Here we predict into the past, using climate, the spatio-temporal structure and the association signal. On the left is the predicted probability of Picea, spruce, through time, with yellow crosses where it was actually recorded; you can see its northward migration after the Last Glacial Maximum. On the right is the predicted genus richness. The logical next step is to use the past to better predict future biodiversity change.

### Slide 13: Take-home messages

Let me summarise. I used 1,130 cores with almost 30,000 spatio-temporal communities, 256 taxa, and almost nine million trait values grouped into 23 functional types, to fit 324 models. Palaeoecological data can be used to reconstruct past biodiversity patterns and to learn about ecological processes.

In space, the association signal is not stronger at local than at continental scales. Taxonomic resolution does change the association signal, but not in the expected direction. Through time, the co-occurrence structure responds to major environmental changes, but the association signal is surprisingly stable.

And a caveat on all of this: the association signal grows with the number of taxa in a model, so it must be compared between models of equal size. Finally, beyond single-species models, palaeoecological data can help to predict future biodiversity and support conservation. All of these results are still preliminary.

### Slide 14: Termination

This is all the time we have with the supercomputer. ORACLE is shutting down.

### Slide 15: Presenter

My name is Ondřej Mottl. I am an assistant professor at Charles University in Prague, where I lead the Laboratory of Quantitative Ecology. To find out more about my work and my lab, scan the QR code. I am happy to talk about any of these topics, so please get in touch.

### Slide 16: Presentation availability

This presentation is part of the BIODYNAMICS project. Everything, including this presentation, is publicly available on the project website and fully reproducible. You can scan the QR code or go to bit.ly/BIODYNAMICS_project.

### Slide 17: Final slide

Thank you very much for your attention. I am looking forward to your questions and comments.

## Extra slides (not part of the recording)

The matrix-scale analyses below sit in the extra slides after the final slide; their notes are kept for questions.

### Slide 11c: Climate versus space: no size effect

Is this simply a property of bigger models? As a control, I looked at the balance between the other two components: the climate part divided by the climate plus space parts. This balance does not change with the number of taxa; the lines are flat. So the size effect is specific to the association component, and the balance between climate and space can be compared between models as it is.

### Slide 11d: At equal matrix size, the gradient reverses

And this matters for the spatial result, because continental models simply hold more taxa: a median of about fifty genera, against about twelve in local models. The dashed green line is the raw median association share for genera, the pattern we saw earlier. The purple line is the share predicted for models of equal size, from a model that holds taxon number, resolution, extent and continent.

At equal size, the gradient reverses into the decline with extent that I originally expected. This is a model-based adjustment and still preliminary, but it shows that the scale question has to be asked at equal matrix size.

### Slide 11e: Same genera across nested extents (first look)

A second way around the size effect is to follow the same genera from a local unit to its region, and from the region to its continent, and compare their association shares. Each point is one unit. The larger model mostly gives the higher share, but the difference grows with how many more taxa it holds, so most of it is again the size effect.

The open symbols show the difference at equal model size: about zero in fossil pollen, but clearly negative in modern vegetation plots, where association therefore declines with extent. This is a first look, so please do not quote it yet.

### Slide 11f: And through time?

The same applies through time. On the left, the number of taxa per 500-year slice rises toward the present in North America and Europe, while northern Asia stays below ten. On the right, the slices and the continent with the fewest taxa have the lowest association shares. So the dips in the temporal trajectories, and the lower shares in Asia, cannot yet be separated from matrix size. The next step is to compare the same taxa through time.
