#ifndef WRITER_PARSER_HPP
#define WRITER_PARSER_HPP

#include <map>
#include <string_view>
#include <iostream>

#include <boost/algorithm/string.hpp>

#include "sqlite3.h"
#include "SQLiteCpp/SQLiteCpp.h"
#include "reflect/reflect.hpp"
#include "parser/parser.hpp"



class Parser : public ParserBase
{
public:
	Parser(SQLite::Database& db)
		: base(db)
	{
		db.exec(""
			"CREATE TABLE IF NOT EXISTS points ("
			"	id			INTEGER PRIMARY KEY, "
			"	coordinates TEXT UNIQUE, "
			"	result		TEXT "
			")"
		);
		db.exec(""
			"CREATE UNIQUE INDEX IF NOT EXISTS coordinates "
			"ON points(coordinates)"
		);
	}

	Parser& LoadRequiredPoints(std::string data)
	{
		ImportPoints(data, points);
		return *this;
	}

	Parser& SavePoints()
	{
		constexpr auto kv = "(?, ?)";
		constexpr auto gs = 499LL;

		int ngroups = ceil((0.f + points.size()) / gs);
		for (auto i = 0LL; i < ngroups; ++i)
		{
			const auto kvs = std::vector<std::string>(gs, kv);
			const auto kvl = boost::join(kvs, ", ");

			auto query = SQLite::Statement(base, ""
				"INSERT INTO points (coordinates, result)"
				"VALUES " + kvl + " "
				"ON CONFLICT(coordinates) DO UPDATE SET result = excluded.result"
			);

			int j = 0;
			auto pos = points.begin() + gs * (i + 0);
			auto end = (i + 1 != ngroups)
				? points.begin() + gs * (i + 1)
				: points.end();
			for (; pos != end; ++pos)
			{
				auto& point = *pos;
				auto  value = point.back();
				std::cout << "k" << std::endl;
				point.pop_back();
				query.bind(++j, boost::join(point, "___"));
				query.bind(++j, value);
			}
			query.exec();

			query.reset();
		}
		return *this;
	}

private:
	SQLite::Database& base;

	ATable points;
};


#endif //!WRITER_PARSER_HPP
