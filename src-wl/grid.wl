(* ::Package:: *)

Package["ultima`"]; PackageScope["grid"]
PackageExport["grid"]
PackageExport["gridDataRoot"]


gridDataRoot = "data/";
gridPackRoot = DirectoryName[ultima`pack`$fileName] <> "/";


grid[db_String, zones_, OptionsPattern[{
	vMode -> "Grid"
}]] := Module[{vmode = OptionValue[vMode]},
	grid`req = gridCalcPoints[zones       , vmode]& // gridTimeing["generate points"];
	grid`out = gridLoadPoints[db, grid`req, vmode]& // gridTimeing["load points"];
	grid`fnd = grid`out[["found"  ]];
	grid`msg = grid`out[["missing"]];
	{
		StringForm["points: ``  found: ``  missing: ``"
			, Length[grid`fnd] + Length[grid`msg]
			, Length[grid`fnd]
			, Length[grid`msg]
		]
	} // Column // Panel // Print;
	
	Return[grid`fnd];
]

grid[db_String, f_, zones_List, OptionsPattern[{
	bParallel   -> True,
	vBucketSize -> 10,
	vMode       -> "Grid"
}]] := Module[{
	vmode    = OptionValue[vMode],
	vbacket  = OptionValue[vBucketSize]
},
	grid`req = gridCalcPoints[zones       , vmode]& // gridTimeing["generate points"];
	grid`out = gridLoadPoints[db, grid`req, vmode]& // gridTimeing["load points"];
	grid`fnd = grid`out[["found"  ]];
	grid`msg = grid`out[["missing"]];
	{
		Dynamic[StringForm["points: ``  processed: `` (``%)"
			, Length[grid`req]
			, Length[grid`fnd]
			, Round[100 N[Length[grid`fnd]/Length[grid`req]], 0.01]
		]]
	} // Column // Panel // Print;
	
	If [OptionValue[bParallel],
		LaunchKernels[] // Quiet;
	];
	
	grid`map[points_] := If [OptionValue[bParallel]
	,   ParallelMap[Append[#, f[#]]&, points, DistributedContexts->{"Global`", "ultima`"}]
	,   Map[f, points];
	];

	grid`job = If [vmode == "Stage", 
		(
			grid`head = #[[1;;-2]];
			grid`tail = #[[-1   ]];
			Append[grid`head , f[grid`head, grid`tail]]
		)&
	, 
		(
			Append[#, f[#]]
		)&
	];
	
	grid`vkernels  = If [OptionValue[bParallel], $KernelCount, 1];
	grid`worker[] := Module[{subpoints = #},
		grid`points = grid`map[subpoints];
		grid`fnd    = Join[grid`fnd, grid`points];
		gridSavePoints[db, grid`points];
	]& /@ Partition[grid`msg, UpTo[vbacket grid`vkernels]];
	
	grid`worker // gridTimeing["process data"];
	
	Return[grid`fnd];
];


(** Internal *)


gridTimeing[name_] := Module[{},
	grid`entery[clb_] := (
		{grid`time, grid`res} = AbsoluteTiming[clb[]];
		grid`time = grid`time // DecimalForm // N;
		Print[StringForm["``: ``s", name, ToString[grid`time]]];
		Return[grid`res];
	);
	Return[grid`entery];
]


gridCalcPoints[zones_, vmode_] := Module[{}, 
	If [vmode != "Grid",
		Return[zones];
	];
	Return[gridCalcPoints[zones]];
]

gridCalcPoints[zones_] := Module[{}, 
	grid`points = gridCalcZonePoints[#]& /@ zones;
	grid`points = Flatten[grid`points, 1];
	grid`points = DeleteDuplicates[grid`points];
	Return[grid`points];
]

gridCalcZonePoints[zone_] := Module[{}, 
	grid`points = {#}& /@ zone[[1]];
	For[grid`i = 2, grid`i <= Length[zone], grid`i++,
		grid`row = zone[[grid`i]];
		grid`points = Table[Append[p, r], {p, grid`points}, {r, grid`row}];
		grid`points = Flatten[grid`points, 1];
	];
	Return[grid`points];
]


gridLoadPoints[db_, req_, vmode_] := Module[{}, 
	If [vmode == "Stage",
		grid`dbtmp = db<>".tmp";
		grid`heads = (#[[1;;-2]]&) /@ req;	
		grid`out = gridLoadPoints[db, grid`heads];
		grid`fnd = grid`out[["found"  ]];
		grid`mis = grid`out[["missing"]];
		
		gridSavePoints[grid`dbtmp, req];
		grid`tmp = gridLoadPoints[grid`dbtmp, grid`mis];
		grid`mis = grid`tmp[["found"]];
		gridDropBase[grid`dbtmp];
		Return[<| 
			"found"   -> grid`fnd,
			"missing" -> grid`mis
		|>];
	];
	Return[gridLoadPoints[db, req]];
]

gridLoadPoints[db_, req_] := Module[{},
	grid`res = gridRun[db, "reader.exe", req];
	grid`res = StringToStream[grid`res];
	grid`res = Read[grid`res];
	Return[<| 
		"found"   -> gridReadFiles[grid`res[["found"  ]]], 
		"missing" -> gridReadFiles[grid`res[["missing"]]]
	|>]
]

gridSavePoints[db_, fnd_] := Module[{},
	gridRun[db, "writer.exe", fnd];
]

(* -------------------------------------------------------- *)
gridWriteToFile[data_] := Module[{}, 
	grid`text = (("'" <> gridForm[#] <> "'")& /@ #& /@ data);
	grid`file = CreateFile[];
	WriteString[grid`file, grid`text];
	Return[grid`file];
]

gridRun[db_, app_, points_] := Module[{}, 
	grid`file = gridWriteToFile[points];
	grid`res  = RunProcess[{
		gridPackRoot <> app, 
		gridDataRoot <> db, 
		grid`file
	}, ProcessDirectory -> NotebookDirectory[]];
	If[grid`res[["ExitCode"]] != 0,
		Print[grid`res];
		Abort[];
	];
	Return[grid`res[["StandardOutput"]]];
]

gridReadFiles[grid`files_] := Module[{},
	grid`points = (
		grid`file = NotebookDirectory[] <> #;
		grid`data = Import[File[grid`file], "Text"];
		grid`data = StringDelete[grid`data, "'"];
		DeleteFile[grid`file];
				
		Read[StringToStream[grid`data]]
	)& /@ grid`files;
	Return[Flatten[grid`points, 1]];
]

gridDropBase[db_] := DeleteFile[NotebookDirectory[] <> gridDataRoot <> db <> ".db3"]

(* -------------------------------------------------------- *)
gridForm[s_      ] := s // DecimalForm // N // ToString
gridForm[s_String] := ("\"" <> s <> "\"")
gridForm[s_List  ] := (gridForm[#]& /@ s) // ToString
