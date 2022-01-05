@echo off
#Fait la différence entre deux shapefiles: l'inventaire des glaciers rocheux et une couche d'occupation des sols pertinents
saga_cmd shapes_polygons 15 -A Inventory.shp -B Ground_occupation.shp -RESULT diff.shp

#Rentre dans l'arborescence de dossier des images à traiter
for /d %%i in ("D*") DO (
    for  %%k in ("%%i\*.asc") DO (
    #Calcule la pente de chaque tuile contenant un glacier à partir d'un MNT
    saga_cmd ta_morphometry 0 -ELEVATION %%k -SLOPE %%i\slope.sgrd -UNIT_SLOPE 1
    #Change la définition de la pente pour la détériorer (temps de calculs trop longs et plantages)
    saga_cmd grid_tools 0 -INPUT %%i\slope.sgrd -OUTPUT %%i\slope.sgrd -TARGET_USER_SIZE 20
    #Transforme la grille de pente en shapefile
    saga_cmd shapes_grid 6 -GRID %%i\slope.sgrd -POLYGONS %%i\slope.shp
    #Stocke l'execution du tri des pentes superieures à 40 degrés dans un txt
    echo shapes_tools 3 -SHAPES %%i\slope.shp -FIELD 1 -EXPRESSION="a > 40" > %%i\selec_pente.txt | echo shapes_tools 6 -INPUT %%i\slope.shp -OUTPUT %%i\slope_sup_seuil.shp >> %%i\selec_pente.txt
    #Execute le txt
    saga_cmd %%i\selec_pente.txt
    #Fusionne les différents polygones en 1 seul (améliore le temps de calcul)
    saga_cmd shapes_polygons 5 -POLYGONS slope_sup_seuil.shp -DISSOLVED slope_sup_seuil.shp
    #Fait la différence entre la couche des glaciers calculée au début et les pentes supérieures à 40 degrés
    saga_cmd shapes_polygons 15 -A diff.shp -B %%i\slope_sup_seuil.shp -RESULT diff.shp
    #supprime les pentes calculées
    del /s %%i\*slope*
    #Parcours les orthoimages aux différentes dates
    for /d %%j in ("%%i\*") DO (
        for %%l in ("%%j\*.tif") DO (
            #Lit les trois bandes RGB de l'image
            saga_cmd io_gdal 0 -FILES %%l -GRIDS "%%j\rouge.sgrd;%%j\vert.sgrd;%%j\bleu.sgrd" -MULTIPLE 0
            #Fait une composition RGB de l'image pour être utilisable dans les algorithmes suivants
            saga_cmd grid_visualisation 3 -R_GRID %%j\rouge.sgrd -G_GRID %%j\vert.sgrd -B_GRID %%j\bleu.sgrd -A_GRID NULL -RGB %%j\rgb.sgrd -METHOD 4 -STDDEV 2.000000
            #Garde la partie intéressante des images en faisant la différence avec le shapefile des zones d'intérets des glaciers
            saga_cmd grid_tools 31 -GRIDS %%j\rgb.sgrd -CLIPPED %%j\rgb.sgrd -EXTENT 3 -POLYGONS diff.shp
            #Supprime les bandes RGB
            del /s %%j\*rouge*
            del /s %%j\*vert*
            del /s %%j\*bleu*
        )
    )
    )
) 
#Parcours les images des glaciers retifiées précédemment
for /d /r %%i in ("D*") DO (
    for /d %%j in ("%%i\*") DO (
        mkdir %%j\Imcorr
        for /d %%k in ("%%i\*") DO (
            IF  %%j == %%k (
                echo Same folder
            ) ELSE (
                #Pour deux images différentes, calcule leur corrélation 
                saga_cmd grid_analysis 19 -GRID_1 %%j\rgb.sgrd -GRID_2 %%k\rgb.sgrd -DTM_1 NULL -DTM_2 NULL -CORRPOINTS %%j\Imcorr\%%~nj_%%~nk_points.shp -CORRLINES %%j\Imcorr\%%~nj_%%~nk_lines.shp -SEARCH_CHIPSIZE 3 -REF_CHIPSIZE 2 -GRID_SPACING 10
            )
        )
    )
)

for /d /r %%i in ("*") DO (
    del /s %%i\*rgb*
)
