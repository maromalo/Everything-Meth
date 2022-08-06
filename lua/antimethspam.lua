local common_patterns = {
    "^add caustic soda$",
    "^add muriatic acid$",
    "^add hydrogen chloride$",
    "^ingredient added$",
    "^batch complete$",
    "^meth batch is done!$",
    "^%[Everything Meth%]",
    "^%[Meth Helper%]"
}

--sooo i just learned it's "receive" and not "recieve"
--why
local original_receive_message = ChatManager._receive_message
function ChatManager:_receive_message(channel_id, name, message, ...)
    if (EverythingMeth.settings.anti_spam and (name ~= managers.network:session():local_peer():name() and name ~= "[" .. EverythingMeth:LocalizeLine("prefix") .. "]")) then
        for _, pattern in pairs(common_patterns) do
            if (message:lower():match(pattern)) then
                return false
            end
        end
    end
    return original_receive_message(self, channel_id, name, message, ...)
end