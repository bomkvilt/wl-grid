(* ::Package:: *)

greedDataRoot = "./data/";

greed[db_, f_, zones_List, OptionsPattern[{
	bParallel   -> False,
	vBucketSize -> 10
}]] := Block[{},
	req = greedCalcPoints[zones]  & // greedTimeing["generate points"];
	out = greedLoadPoints[db, req]& // greedTimeing["load points"];
	fnd = out[["found"  ]];
	msg = out[["missing"]];
	
	vState = 0;
	bActive  := vState == 0;
	bPaused  := vState > 0;
	bStopped := vState > 1;
	{
		{
			Button["Pause", vState = 1],
			Button["Stop" , vState = 2]
		} // Row
		, Dynamic[
			StringForm["points: ``  processed: `` (``%)"
				, Length[req]
				, Length[fnd]
				, 100 N[Length[fnd]/Length[req]]
			]
		]
	} // Column // Panel // Print;
	
	task[point_] := Block[{},
		If   [bStopped, Return[]];
		While[!bActive, Pause[1]];
		
		res = f[point];
		res = Append[point, res];
		Return[res];
	];
	
	map[points_] := If [!OptionValue[bParallel]
	,   Return[Map[task, points]]
	,   
		groups  = Partition[points, UpTo[Ceiling[Length[points] / $KernelCount]]];
		results = ParallelMap[Function[{subpoints},
			task /@ subpoints
		], groups];
		Return[Flatten[results, 1]];
	];
	
	worker[] := Block[{subpoints = #},
		If [bStopped, Return[]];
		
		points = map[subpoints];
		fnd = Join[fnd, points];
		greedSavePoints[db, points];
	]& /@ Partition[msg, UpTo[Max[
		OptionValue[vBucketSize] If [OptionValue[bParallel], $KernelCount, 1],
		OptionValue[vBucketSize] 1
	]]];
	
	If [OptionValue[bParallel],
		SetSharedVariable[vState];
		LaunchKernels[] // Quiet;
	];
	worker // greedTimeing["process data"];
	
	Return[fnd];
];


(** Internal *)


greedTimeing[name_] := Block[{},
	entery[clb_] := (
		{time, res} = AbsoluteTiming[clb[]];
		Print[StringForm["``: ``s", name, ToString[time]]];
		Return[res];
	);
	Return[entery];
];


greedCalcPoints[zones_] := Block[{},
	points = {};
	(
		zonePoints = greedCalcZonePoints[#];
		points = Join[points, zonePoints];
	) & /@ zones;
	points = DeleteDuplicates[points];
	Return[points];
];

greedCalcZonePoints[zone_] := Block[{},
	points = {#}& /@ zone[[1]];
	For[i = 2, i <= Length[zone], i++,
		row = zone[[i]];
		points = Table[Append[p, r], {p, points}, {r, row}];
		points = Flatten[points, 1];
	];
	Return[points];
];


greedLoadPoints[db_, req_] := Block[{},
	out = greedRun[db, "reader.exe", req];	
	found   = "found"   /. out;
	missing = "missing" /. out;
	Return[<| 
		"found"   -> found, 
		"missing" -> missing
	|>]
]

greedSavePoints[db_, fnd_] := Block[{},
	greedRun[db, "writer.exe", fnd];
];

(* -------------------------------------------------------- *)
greedWriteToFile[data_] := (
	toString[s_] := "'" <> ToString[s] <> "'";
	text = ((toString[#]& /@ #& /@ data)// ToString);
	file = CreateFile[];
	WriteString[file, text];	
	Return[file];
);

greedRun[db_, app_, points_] := (
	file = greedWriteToFile[points];
	res  = RunProcess[{NotebookDirectory[] <> app, greedDataRoot <> db, file}
		, ProcessDirectory->NotebookDirectory[]
	];	
	If[res[["ExitCode"]] != 0,
		Print[res];
		Abort[];
	];
	
	res = res[["StandardOutput"]];
	res = StringDelete[res, "'"];
	res = StringToStream[res];
	res = Read[res];
	Return[res];
);
