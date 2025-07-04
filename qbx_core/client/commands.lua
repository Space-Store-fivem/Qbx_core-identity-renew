-- Função para encontrar o jogador mais próximo na frente
lib.callback.register('qbx_core:client:getPlayerInFront', function(source)
    local playerPed = PlayerPedId()
    local closestPlayer, closestDistance = -1, 2.0

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= playerPed then
            local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed))
            if distance < closestDistance then
                closestPlayer = GetPlayerServerId(player)
                closestDistance = distance
            end
        end
    end
    return closestPlayer
end)

-- Evento para tocar as animações de abordagem
RegisterNetEvent('qbx_core:client:playAbordagemAnimation', function(officerId, targetId)
    local source = GetPlayerServerId(PlayerId())

    if source == officerId then
        -- Animação para o policial (opcional, pode ser só ficar parado)
        -- Ex: TaskPlayAnim(PlayerPedId(), "anim_dict", "anim_name", 8.0, -8.0, -1, 1, 0, false, false, false)
    elseif source == targetId then
        -- Animação para o abordado (mãos para cima)
        local playerPed = PlayerPedId()
        RequestAnimDict("random@arrests")
        while not HasAnimDictLoaded("random@arrests") do
            Wait(100)
        end
        TaskPlayAnim(playerPed, "random@arrests", "handsup_enter", 8.0, -8.0, -1, 2, 0, false, false, false)
    end
end)