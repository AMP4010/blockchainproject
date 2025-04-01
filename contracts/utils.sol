// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library utils {
	struct persInfo {
		string name;
		uint8 age;
		uint8 bloodtype;
		string hospital;
	}

    struct HLA {
		string a1;
		string a2;
		string b1;
		string b2;
		string c1;
		string c2;
		string drb1_1;
		string drb1_2;
		string dqb1_1;
		string dqb1_2;
	}

	struct orgdet {
		persInfo info;
		string organ;
		uint8 quantity;
		HLA report;
	}

	struct matched_orgdet {
		persInfo donInfo;
		persInfo recInfo;
		string organ;
		uint8 donorquantity;
		uint8 recipientquantity;
		uint8 matchedquantity;
		HLA don_rep;
		HLA rec_rep;
	}

	event MatchFound(
		utils.persInfo info,
		string organ,
		uint8 qty,
		uint8 matchPC
	);

	function getPosBT(uint8 _bloodtype, uint8[10][10] memory _compatMatrix, uint8[] storage _posBT, uint8 _mode) internal {
		if (_bloodtype == 8 || _bloodtype == 9) {
			_posBT.push(_bloodtype);
			return;
		}
		if (_mode == 0) {
			for (uint8 i = 0; i < 8; i++) {
				if (_compatMatrix[i][_bloodtype] == 1) {
					_posBT.push(i);
				}
			}
		} else {
			for (uint8 i = 0; i < 8; i++) {
				if (_compatMatrix[_bloodtype][i] == 1) {
					_posBT.push(i);
				}
			}
		}
	}

    function lowerString(string memory _text) internal pure returns (string memory) {
		bytes memory btext = bytes(_text);
		for (uint256 i = 0; i < btext.length; i++) {
			if (btext[i] >= 0x41 && btext[i] <= 0x5A) {
                btext[i] = bytes1(uint8(btext[i]) + 32);
            }
		}
		return string(btext);
	}

	function containsBT(uint8 _dbt, uint8[] memory _posBT) internal pure returns (bool) {
		bool c = false;
		for (uint8 i = 0; i < _posBT.length; i++) {
			if (_posBT[i] == _dbt) {
				c = true;
			}
		}	
		return c;
	}

    function compAll(string memory o1_all, string memory o2_all) internal pure returns (uint8) {
		bool a = ((uint8(bytes(o1_all)[0]) - 48) * 10 + (uint8(bytes(o1_all)[1]) - 48)) == ((uint8(bytes(o2_all)[0]) - 48) * 10 + (uint8(bytes(o2_all)[1]) - 48));
        bool b = ((uint8(bytes(o1_all)[3]) - 48) * 10 + (uint8(bytes(o1_all)[4]) - 48)) == ((uint8(bytes(o2_all)[3]) - 48) * 10 + (uint8(bytes(o2_all)[4]) - 48));
		bool c = ((uint8(bytes(o1_all)[6]) - 48) * 10 + (uint8(bytes(o1_all)[7]) - 48)) == ((uint8(bytes(o2_all)[6]) - 48) * 10 + (uint8(bytes(o2_all)[7]) - 48));
		if (a && b && c) {
			return 1;
		} else {
			return 0;
		}
	}

    function getHlaCat(string memory _organ, mapping(uint256 => string[]) storage minHLA) internal view returns (uint256) {
        uint8[5] memory minScores = [9, 7, 5, 2, 0];
        uint256 cat;
        for (uint256 i = 0; i < minScores.length; i++) {
            string[] memory organs = minHLA[minScores[i]];
            for (uint256 j = 0; j < organs.length; j++) {
                if (keccak256(bytes(organs[j])) == keccak256(bytes(_organ))) {
                    cat = minScores[i];
                }
            }
		}
        return cat;
    }

	function getHLA(HLA memory _don_rep, HLA memory _rec_rep, uint8 min) internal pure returns (uint8) {
		min += compAll(_don_rep.a1, _rec_rep.a1) + compAll(_don_rep.a2, _rec_rep.a2);
		min += compAll(_don_rep.b1, _rec_rep.b1) + compAll(_don_rep.b2, _rec_rep.b2);
		min += compAll(_don_rep.c1, _rec_rep.c1) + compAll(_don_rep.c2, _rec_rep.c2);
		min += compAll(_don_rep.drb1_1, _rec_rep.drb1_1) + compAll(_don_rep.drb1_2, _rec_rep.drb1_2);
		min += compAll(_don_rep.dqb1_1, _rec_rep.dqb1_1) + compAll(_don_rep.dqb1_2, _rec_rep.dqb1_2);
		return min;
	}

	function pop(orgdet[] storage _list, uint256 _i) internal {
		orgdet memory temp = _list[_i];
		_list[_i] = _list[_list.length - 1];
		_list[_list.length - 1] = temp;
		_list.pop();
	}

	function pushMatch(matched_orgdet[] storage _matchedList, persInfo memory _donInfo, persInfo memory _recInfo, string memory _organ, uint8 _dqty, uint8 _rqty, uint8 _mqty, HLA memory _don_rep, HLA memory _rec_rep) internal {
		matched_orgdet memory match_det = matched_orgdet({
			donInfo: _donInfo,
			recInfo: _recInfo,
			organ: _organ,
			donorquantity: _dqty,
			recipientquantity: _rqty,
			matchedquantity: _mqty,
            don_rep: _don_rep,
			rec_rep: _rec_rep
		});
		_matchedList.push(match_det);
	}

	function pushNew(orgdet[] storage _list, persInfo memory _persInfo, string memory _organ, uint8 _quantity, HLA memory _report) internal {
		orgdet memory newEntry = orgdet({
			info: _persInfo,
			organ: _organ,
			quantity: _quantity,
			report:_report
		});
        _list.push(newEntry);
	}

	function initProcessing(uint256 i, orgdet[] storage donorList, orgdet[] storage recipientList, matched_orgdet[] storage matchedList, uint8 mS, persInfo memory _d_info, string memory _org, uint8 _d_qty, HLA memory _d_rep, persInfo memory _r_info, uint8 _r_qty, HLA memory _r_rep, uint8 _mode) internal {
		if (_mode == 0) {
			uint8 matchPC = (mS/10) * 100;
			emit MatchFound(_r_info, _org, _r_qty, matchPC);
			int8 pendingqty = int8(_d_qty) - int8(_r_qty);
			if (pendingqty > 0) {
				utils.pushMatch(matchedList, _d_info, _r_info, _org, _d_qty, _r_qty, _r_qty, _d_rep, _r_rep);
				utils.pushNew(donorList, _d_info, _org, uint8(pendingqty), _d_rep);
				utils.pop(recipientList, i);
			} else if (pendingqty == 0) {
				utils.pushMatch(matchedList, _d_info, _r_info, _org, _d_qty, _r_qty, _r_qty, _d_rep, _r_rep);
				utils.pop(recipientList, i);
			} else {
				utils.pushMatch(matchedList, _d_info, _r_info, _org, _d_qty, _r_qty, _r_qty, _d_rep, _r_rep);
				recipientList[i].quantity = uint8(pendingqty * -1);
			}
		} else {
			uint8 matchPC = (mS/10) * 100;
			emit MatchFound(_d_info, _org, _d_qty, matchPC);
			int8 remainingqty = int8(_r_qty) - int8(_d_qty);
			if (remainingqty > 0 ) {
				utils.pushMatch(matchedList, _d_info, _r_info, _org, _d_qty, _r_qty, _d_qty, _d_rep, _r_rep);
				utils.pushNew(recipientList, _r_info, _org, uint8(remainingqty), _r_rep);
				utils.pop(donorList, i);
			} else if (remainingqty == 0) {
				utils.pushMatch(matchedList, _d_info, _r_info, _org, _d_qty, _r_qty, _d_qty, _d_rep, _r_rep);
				utils.pop(donorList, i);
			} else {
				utils.pushMatch(matchedList, _d_info, _r_info, _org, _d_qty, _r_qty, _d_qty, _d_rep, _r_rep);
				donorList[i].quantity = uint8(remainingqty * -1);
			}
		}
	}
}