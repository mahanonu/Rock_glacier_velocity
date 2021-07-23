@echo off
saga_cmd shapes_polygons 15 -A Complete_Inventory_Final3.shp -B CLC_test.shp -RESULT diff.shp

for /d %%i in ("D*") DO (
    for  %%k in ("%%i\*.asc") DO (
    saga_cmd ta_morphometry 0 -ELEVATION %%k -SLOPE %%i\slope.sgrd -UNIT_SLOPE 1
    saga_cmd grid_tools 0 -INPUT %%i\slope.sgrd -OUTPUT %%i\slope.sgrd -TARGET_USER_SIZE 20
    saga_cmd shapes_grid 6 -GRID %%i\slope.sgrd -POLYGONS %%i\slope.shp
    echo shapes_tools 3 -SHAPES %%i\slope.shp -FIELD 1 -EXPRESSION="a > 40" > %%i\selec_pente.txt | echo shapes_tools 6 -INPUT %%i\slope.shp -OUTPUT %%i\slope_sup_seuil.shp >> %%i\selec_pente.txt
    saga_cmd %%i\selec_pente.txt
    saga_cmd shapes_polygons 5 -POLYGONS slope_sup_seuil.shp -DISSOLVED slope_sup_seuil.shp
    saga_cmd shapes_polygons 15 -A diff.shp -B %%i\slope_sup_seuil.shp -RESULT diff.shp
    del /s %%i\*slope*
    saga_cmd grid_tools 31 -GRIDS 
    for /d %%j in ("%%i\*") DO (
        for %%l in ("%%j\*.tif") DO (
            saga_cmd io_gdal 0 -FILES %%l -GRIDS "%%j\rouge.sgrd;%%j\vert.sgrd;%%j\bleu.sgrd" -MULTIPLE 0
            saga_cmd grid_visualisation 3 -R_GRID %%j\rouge.sgrd -G_GRID %%j\vert.sgrd -B_GRID %%j\bleu.sgrd -A_GRID NULL -RGB %%j\rgb.sgrd -METHOD 4 -STDDEV 2.000000
            saga_cmd grid_tools 31 -GRIDS %%j\rgb.sgrd -CLIPPED %%j\rgb.sgrd -EXTENT 3 -POLYGONS diff.shp
            del /s %%j\*rouge*
            del /s %%j\*vert*
            del /s %%j\*bleu*
        )
    )
    )
) 
REM for /d /r %%i in ("D*") DO (
REM     for /d %%j in ("%%i\*") DO (
REM         mkdir %%j\Imcorr
REM         for /d %%k in ("%%i\*") DO (
REM             IF  %%j == %%k (
REM                 echo Same folder
REM             ) ELSE (
REM                 saga_cmd grid_analysis 19 -GRID_1 %%j\rgb.sgrd -GRID_2 %%k\rgb.sgrd -DTM_1 NULL -DTM_2 NULL -CORRPOINTS %%j\Imcorr\%%~nj_%%~nk_points.shp -CORRLINES %%j\Imcorr\%%~nj_%%~nk_lines.shp -SEARCH_CHIPSIZE 3 -REF_CHIPSIZE 2 -GRID_SPACING 10
REM             )
REM         )
REM     )
REM )
REM 
REM for /d /r %%i in ("*") DO (
REM     del /s %%i\*rgb*
REM )