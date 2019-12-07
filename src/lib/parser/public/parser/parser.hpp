#ifndef PARSER_PARSER_HPP
#define PARSER_PARSER_HPP

#include <vector>
#include <string>
#include <algorithm>
#include <boost/spirit/include/qi.hpp>
#include <boost/algorithm/string.hpp>

namespace qi = boost::spirit::qi;



class ParserBase
{
public:
	using ATable  = std::vector<std::vector<std::string>>;
public:
	
	ParserBase()
	{
		constexpr auto qt = '\'';
		string_ = qi::lexeme[qt >> +(qi::char_ - qt) >> qt];
		row_    = "{" >> -(string_ % ",") >> "}";
		rows_   = "{" >> -(row_    % ",") >> "}";
	}

	void ImportPoints(const std::string& data, ATable& imported)
	{
		auto pos = data.begin();
		auto end = data.end();
		auto res = Rows();

		qi::phrase_parse(pos, end, rows_, qi::space, res);
		if (pos != end)
		{
			throw std::runtime_error("unparsed part: " + std::string(pos, end));
		}
		
		for (auto& row : res)
		{
			imported.emplace_back(row.begin(), row.end());
		}
	}

	std::string ExportPoints(const ATable& exported) const
	{
		auto ss = std::stringstream();
		ss << "{";
		auto tmp = std::vector<std::string>();
		for (auto& row : exported)
		{
			tmp.push_back("{" + boost::join(row, ",") + "}");
		}
		ss << boost::join(tmp, ",");
		ss << "}";
		return ss.str();
	}

private:
	using It      = std::string::const_iterator;
	using Skipper = qi::space_type;
	using Row     = std::vector<std::string>;
	using Rows    = std::vector<Row>;

	qi::rule<It, std::string(), Skipper> string_;
	qi::rule<It, Row(),  Skipper> row_;
	qi::rule<It, Rows(), Skipper> rows_;
};

#endif //!PARSER_PARSER_HPP
