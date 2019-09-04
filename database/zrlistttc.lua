-- zrlistttc.lua
-- Copyright (c) 2019 Takayuki YATO
-- Modified by Hironobu YAMASHITA
-- This software is distributed under the MIT License.
prog_name = 'zrlistttc'
version = '0.4'
mod_date = '2019/08/31'
----------------------------------------
verbose = false
ttc_index = nil
content = { 6 }
langid = nil
ttc_file = nil
----------------------------------------
do
  local reader_meta = {
    __tostring = function(self)
      return "reader("..self.name..")"
    end;
    __index = {
      cdata = function(self, ofs, len)
        return make_cdata(self:read(ofs, len))
      end;
      read = function(self, ofs, len)
        self.file:seek("set", ofs)
        local data = self.file:read(len)
        sure(data:len() == len, 1)
        return data
      end;
      close = function(self)
        self.file:close()
      end;
    }
  }
  function make_reader(fname)
    local file = io.open(fname, "rb")
    sure(file, "cannot open for input", fname)
    return setmetatable({
      name = fname, file = file
    }, reader_meta)
  end
end
----------------------------------------
do
  local cdata_meta = {
    __tostring = function(self)
      return "cdata(pos="..self._pos..")"
    end;
    __index = {
      pos = function(self, p)
        if not p then return self._pos end
        self._pos = p
        return self
      end;
      _unum = function(self, b)
        local v, data = 0, self.data
        sure(#data >= self._pos + b, 11)
        for i = 1, b do
          self._pos = self._pos + 1
          v = v * 256 + data:byte(self._pos)
        end
        return v
      end;
      _setunum = function(self, b, v)
        local t, data = {}, self.data
        t[1] = data:sub(1, self._pos)
        self._pos = self._pos + b
        sure(#data >= self._pos, 12)
        t[b + 2] = data:sub(self._pos + 1)
        for i = 1, b do
          t[b + 2 - i] = string.char(v % 256)
          v = math.floor(v / 256)
        end
        self.data = table.concat(t, '')
        return self
      end;
      str = function(self, b)
        local data = self.data
        self._pos = self._pos + b
        sure(#data >= self._pos, 13)
        return data:sub(self._pos - b + 1, self._pos)
      end;
      setstr = function(self, s)
        local t, data = {}, self.data
        t[1], t[2] = data:sub(1, self._pos), s
        self._pos = self._pos + #s
        sure(#data >= self._pos, 14)
        t[3] = data:sub(self._pos + 1)
        self.data = table.concat(t, '')
        return self
      end;
      ushort = function(self)
        return self:_unum(2)
      end;
      ulong = function(self)
        return self:_unum(4)
      end;
      setulong = function(self, v)
        return self:_setunum(4, v)
      end;
      ulongs = function(self, num)
        local t = {}
        for i = 1, num do
          t[i] = self:_unum(4)
        end
        return t
      end;
    }
  }
  function make_cdata(data)
    return setmetatable({
      data = data, _pos = 0
    }, cdata_meta)
  end
end
----------------------------------------
do
  local floor, ceil = math.floor, math.ceil
  local function div(x, y)
    return floor(x / y), x % y
  end
  local function utf16betoutf8(src)
    local s, d = { tostring(src):byte(1, -1) }, {}
    for i = 1, #s - 1, 2 do
      local c = s[i] * 256 + s[i+1]
      if c < 0x80 then d[#d+1] = c
      elseif c < 0x800 then
        local x, y = div(c, 0x40)
        d[#d+1] = x + 0xC0; d[#d+1] = y + 0x80
      elseif c < 0x10000 then
        local x, y, z = div(c, 0x1000); y, z = div(y, 0x40)
        d[#d+1] = x + 0xE0; d[#d+1] = y + 0x80; d[#d+1] = z + 0x80
      else sure(nil)
      end
    end
    return string.char(unpack(d))
  end
  local file_type = {
    [0x74746366] = 'ttc'; [0x10000] = 'ttf'; [0x4F54544F] = 'otf';
    [0x74727565] = 'ttf'
  }
  function otf_offset(reader)
    local cd = reader:cdata(0, 12)
    local tag = cd:ulong()
    local ftype = file_type[tag]; info("type", ftype)
    if ftype == 'ttc' then
      local ver = cd:ulong(); info("version", ver)
      local num = cd:ulong(); info("#fonts", num)
      cd = reader:cdata(12, 4 * num)
      local res = cd:ulongs(num); info("offset", stt(res))
      return res
    elseif ftype == 'otf' or ftype == 'ttf' then
      return { 0 }
    else sure(nil, "unknown file tag", tag)
    end
  end
  local function otf_name_table(reader, fofs, ntbl)
    local cd_d = reader:cdata(fofs + 12, 16 * ntbl)
    for i = 1, ntbl do
      local t = stt({-- tag, csum, ofs, len
        cd_d:str(4), cd_d:ulong(), cd_d:ulong(), cd_d:ulong()
      })
      if t[1] == 'name' then
        info("name table index", i)
        return reader:cdata(t[3], ceil(t[4] / 4) * 4)
      end
    end
    sure(nil, "name table is missing")
  end
  local function otf_name_records(cdata)
    local nfmt, nnum, nofs = cdata:ushort(), cdata:ushort(), cdata:ushort()
    sure(nfmt == 0, "unsupported name table format", nfmt)
    local nr = stt({})
    for i = 1, nnum do
      nr[i] = stt({ -- pid, eid, langid, nameid, len, ofs
        cdata:ushort(), cdata:ushort(), cdata:ushort(),
        cdata:ushort(), cdata:ushort(), cdata:ushort() + nofs
      })
    end
    return nr
  end
  function otf_name(cdata, nr, nameid)
    local function seek(pid, eid, lid)
      for i = 1, #nr do
        local t = nr[i]
        local ok = (t[4] == nameid and t[1] == pid and t[2] == eid and
            t[3] == lid)
        if ok then return t end
      end
    end
    local rec
    if langid then
      rec = seek(unpack(langid))
    else
      rec = seek(3, 1, 0x409) or seek(3, 10, 0x409) or
        seek(1, 0, 0) or seek(0, 3, 0) or
        seek(0, 4, 0) or seek(0, 6, 0)
    end
    info("name record", rec or 'none')
    if not rec then return '' end
    local s = cdata:pos(rec[6]):str(rec[5])
    return (rec[1] == 3) and utf16betoutf8(s) or s
  end
  function otf_list(reader, fid, fofs)
    local cd_fh = reader:cdata(fofs, 12)
    local tag = cd_fh:ulong(); info("tag", tag)
    local ntbl = cd_fh:ushort(); info("#tables", ntbl)
    local cd_n = otf_name_table(reader, fofs, ntbl)
    local ext = { id = fid; type = file_type[tag] or '' }
    local nr, val = otf_name_records(cd_n), stt({})
    info("font", otf_name(cd_n, nr, 6))
    for i = 1, #content do
      local key = content[i]
      val[i] = (type(key) == 'string') and ext[key] or
          otf_name(cd_n, nr, key)
    end
    io.stdout:write(concat(val, ",").."\n")
  end
end
----------------------------------------
do
  unpack = unpack or table.unpack
  local stt_meta = {
    __tostring = function(self)
      return "{"..concat(self, ",").."}"
    end
  }
  function stt(tbl)
    return setmetatable(tbl, stt_meta)
  end
  function concat(tbl, ...)
    local t = {}
    for i = 1, #tbl do t[i] = tostring(tbl[i]) end
    return table.concat(t, ...)
  end
  function info(...)
    if not verbose then return end
    local t = { prog_name, ... }
    io.stderr:write(concat(t, ": ").."\n")
  end
  function abort(...)
    verbose = true; info(...)
    os.exit(-1)
  end
  function sure(val, a1, ...)
    if val then return val end
    if type(a1) == "number" then
      a1 = "error("..a1..")"
    end
    abort(a1, ...)
  end
end
----------------------------------------
do
  local function show_usage()
    io.stdout:write(([[
This is %s v%s <%s> by 'ZR'
Usage: %s[.lua] [-v] [-c <spec>] <ttc_file>
  -v    be verbose
  -i    show only one font with a specified index
  -c    content specification; comma-separated list of items,
        where an item is either 'id', 'type', or an name-ID
]]):format(prog_name, version, mod_date, prog_name))
    os.exit(0)
  end
  local function langid_spec(str)
    local p, e, l = str:match('^(%d+),(%d+),(%d+)$')
    sure(p, "invalid langid spec", str)
    return { tonumber(p), tonumber(e), tonumber(l) }
  end
  local function content_spec(str)
    local t, repo = {}, {
      copyright = 0; family = 1; subfamily = 2; fullname = 4;
      version = 5; psname = 6; url = 11; license = 13;
      tfamily = 16; tsubfamily = 17;
      id = -1; type = -1;
    }
    for k in str:gmatch('[^,]+') do
      local v = (k:match('^%d+$')) and tonumber(k) or repo[k]
      sure(v, "unknown content key", k)
      t[#t+1] = (v < 0) and k or v
    end
    return t
  end
  local function ttc_index_spec(str)
    local p = str:match('^(%d+)$')
    sure(p, "invalid ttc_index spec", str)
    return tonumber(p)
  end
  function read_option()
    if #arg == 0 then show_usage() end
    local idx = 1
    while idx <= #arg do
      local opt = arg[idx]
      if opt:sub(1, 1) ~= '-' then break end
      if opt == '-h' or opt == '--help' then
        show_usage()
      elseif opt == '-v' then
        verbose = true
      elseif opt == '-i' then
        idx = idx + 1; sure(arg[idx], "ttc_index spec is missing")
        ttc_index = ttc_index_spec(arg[idx])
      elseif opt == '-c' then
        idx = idx + 1; sure(arg[idx], "content spec is missing")
        content = stt(content_spec(arg[idx]))
      elseif opt == '-l' then
        idx = idx + 1; sure(arg[idx], "langid spec is missing")
        langid = stt(langid_spec(arg[idx]))
      else abort("invalid option", opt)
      end
      idx = idx + 1
    end
    sure(#arg == idx, "wrong number of arguments")
    ttc_file = arg[idx]
  end
  function main()
    read_option()
    local reader = make_reader(ttc_file)
    local tofs = otf_offset(reader)
    if ttc_index then
      if ttc_index < 0 or ttc_index > #tofs - 1 then
        abort("non-existing ttc_index", ttc_index)
      end
        otf_list(reader, ttc_index, tofs[ttc_index + 1])
    else
      for i = 1, #tofs do
        otf_list(reader, i - 1, tofs[i])
      end
    end
    reader:close()
  end
end
----------------------------------------
main()
-- EOF
