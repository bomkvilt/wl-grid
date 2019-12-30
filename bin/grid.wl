(* ::Package:: *)

gridDataRoot = "data/";
gridPackRoot = NotebookDirectory[];

grid[db_String, zones_] := Module[{},
	grid`out = gridLoadPoints[db, grid`req]& // gridTimeing["load points"];
	grid`fnd = grid`out[["found"  ]];
	grid`msg = grid`out[["missing"]];
	{
		StringForm["points: ``  found: ``  missing: ``"
			, Length[grid`fnd + grid`msg]
			, Length[grid`fnd]
			, Length[grid`msg]
		]
	} // Column // Panel // Print;
	
	Return[grid`fnd];
]

grid[db_String, f_, zones_List, OptionsPattern[{
	bParallel   -> False,
	vBucketSize -> 10
}]] := Module[{},	
	grid`req = gridCalcPoints[zones       ]& // gridTimeing["generate points"];
	grid`out = gridLoadPoints[db, grid`req]& // gridTimeing["load points"];
	grid`fnd = grid`out[["found"  ]];
	grid`msg = grid`out[["missing"]];
	
	grid`vState = 0;
	grid`bActive  := grid`vState == 0;
	grid`bPaused  := grid`vState > 0;
	grid`bStopped := grid`vState > 1;
	If [OptionValue[bParallel],
		SetSharedVariable[grid`vState];
		LaunchKernels[] // Quiet;
	];
	
	{ (* Print interface *)
		{
			Button["Pause", grid`vState = 1],
			Button["Stop" , grid`vState = 2]
		} // Row
		, Dynamic[
			StringForm["points: ``  processed: `` (``%)"
				, Length[grid`req]
				, Length[grid`fnd]
				, 100 N[Length[grid`fnd]/Length[grid`req]]
			]
		]
	} // Column // Panel // Print;
	
	grid`map[clb_, points_] := If [OptionValue[bParallel]
	,   Return[ParallelMap[clb, points]]
	,   Return[Map[clb, points]]
	];
	
	grid`worker[] := Module[{subpoints = #},
		If [grid`bStopped, Return[]];
		
		grid`points = grid`map[(
			If   [ grid`bStopped, Return[]];
			While[!grid`bActive , Pause[1]];
			Append[#, f[#]]
		)&, subpoints];
		grid`fnd = Join[grid`fnd, grid`points];
		gridSavePoints[db, grid`points];
	]& /@ Partition[grid`msg, UpTo[Max[
		OptionValue[vBucketSize] If [OptionValue[bParallel], $KernelCount, 1],
		OptionValue[vBucketSize] 1
	]]];
	
	grid`worker // gridTimeing["process data"];
	
	Return[grid`fnd];
];


(** Internal *)


gridTimeing[name_] := Module[{},
	grid`entery[clb_] := (
		{grid`time, grid`res} = AbsoluteTiming[clb[]];
		Print[StringForm["``: ``s", name, ToString[grid`time]]];
		Return[grid`res];
	);
	Return[grid`entery];
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


gridLoadPoints[db_, req_] := Module[{}, 
	grid`out = gridRun[db, "reader.exe", req];
	grid`found   = "found"   /. grid`out;
	grid`missing = "missing" /. grid`out;
	Return[<| 
		"found"   -> grid`found, 
		"missing" -> grid`missing
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
	}
		, ProcessDirectory -> NotebookDirectory[]
	];
	If[grid`res[["ExitCode"]] != 0,
		Print[grid`res];
		Abort[];
	];
	
	grid`res = grid`res[["StandardOutput"]];
	grid`res = StringDelete [grid`res, "'"];
	grid`res = StringReplace[grid`res, "e" -> "*10^"];
	grid`res = StringToStream[grid`res];
	grid`res = Read[grid`res];
	Return[grid`res];
]

(* -------------------------------------------------------- *)
gridForm[s_      ] := s // DecimalForm // N // ToString
gridForm[s_String] := ("\"" <> s <> "\"")
gridForm[s_List  ] := (gridForm[#]& /@ s) // ToString
